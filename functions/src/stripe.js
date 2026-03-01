const admin = require("firebase-admin");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

const REGION = "asia-northeast1";

function getStripe(secretKey) {
  return require("stripe")(secretKey);
}

/**
 * 1. Express アカウント作成
 */
exports.createConnectAccount = onCall(
  { region: REGION, secrets: [stripeSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "ログインが必要です");
    }

    const uid = request.auth.uid;
    const email = request.data.email || "";

    const stripe = getStripe(stripeSecretKey.value());

    try {
      // 既存アカウントチェック
      const profileRef = admin.firestore().collection("profiles").doc(uid);
      const profile = await profileRef.get();
      const profileData = profile.exists ? profile.data() : {};

      if (profileData.stripeAccountId) {
        // 既にアカウントがある場合はオンボーディングリンクを返す
        const accountLink = await stripe.accountLinks.create({
          account: profileData.stripeAccountId,
          refresh_url: request.data.refreshUrl || "https://albawork.app/stripe/refresh",
          return_url: request.data.returnUrl || "https://albawork.app/stripe/return",
          type: "account_onboarding",
        });
        return { url: accountLink.url, accountId: profileData.stripeAccountId };
      }

      // 新規 Express アカウント作成
      const account = await stripe.accounts.create({
        type: "express",
        country: "JP",
        email: email || undefined,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
        business_type: "individual",
      });

      // プロフィールにStripeアカウントID保存
      await profileRef.set(
        {
          stripeAccountId: account.id,
          stripeAccountStatus: "pending",
        },
        { merge: true },
      );

      // オンボーディングリンク生成
      const accountLink = await stripe.accountLinks.create({
        account: account.id,
        refresh_url: request.data.refreshUrl || "https://albawork.app/stripe/refresh",
        return_url: request.data.returnUrl || "https://albawork.app/stripe/return",
        type: "account_onboarding",
      });

      logger.info("Stripe Connect account created", { uid, accountId: account.id });

      return { url: accountLink.url, accountId: account.id };
    } catch (e) {
      logger.error("createConnectAccount failed", e);
      throw new HttpsError("internal", `Stripeアカウント作成に失敗: ${e.message}`);
    }
  },
);

/**
 * 2. オンボーディングURL再生成
 */
exports.createAccountLink = onCall(
  { region: REGION, secrets: [stripeSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "ログインが必要です");
    }

    const uid = request.auth.uid;
    const stripe = getStripe(stripeSecretKey.value());

    const profileRef = admin.firestore().collection("profiles").doc(uid);
    const profile = await profileRef.get();
    const accountId = profile.data()?.stripeAccountId;

    if (!accountId) {
      throw new HttpsError("not-found", "Stripeアカウントが見つかりません");
    }

    try {
      const accountLink = await stripe.accountLinks.create({
        account: accountId,
        refresh_url: request.data.refreshUrl || "https://albawork.app/stripe/refresh",
        return_url: request.data.returnUrl || "https://albawork.app/stripe/return",
        type: "account_onboarding",
      });

      return { url: accountLink.url };
    } catch (e) {
      logger.error("createAccountLink failed", e);
      throw new HttpsError("internal", `リンク生成に失敗: ${e.message}`);
    }
  },
);

/**
 * 3. アカウント状態確認
 */
exports.getAccountStatus = onCall(
  { region: REGION, secrets: [stripeSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "ログインが必要です");
    }

    const uid = request.auth.uid;
    const stripe = getStripe(stripeSecretKey.value());

    const profileRef = admin.firestore().collection("profiles").doc(uid);
    const profile = await profileRef.get();
    const accountId = profile.data()?.stripeAccountId;

    if (!accountId) {
      return { status: "not_created", chargesEnabled: false, payoutsEnabled: false };
    }

    try {
      const account = await stripe.accounts.retrieve(accountId);

      const status = account.charges_enabled && account.payouts_enabled ?
        "active" :
        account.details_submitted ?
          "pending_verification" :
          "onboarding_incomplete";

      // ステータス更新
      await profileRef.set({ stripeAccountStatus: status }, { merge: true });

      return {
        status,
        chargesEnabled: account.charges_enabled,
        payoutsEnabled: account.payouts_enabled,
        detailsSubmitted: account.details_submitted,
      };
    } catch (e) {
      logger.error("getAccountStatus failed", e);
      throw new HttpsError("internal", `ステータス取得に失敗: ${e.message}`);
    }
  },
);

/**
 * 4. 決済作成（PaymentIntent）
 */
exports.createPaymentIntent = onCall(
  { region: REGION, secrets: [stripeSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "ログインが必要です");
    }

    const { applicationId, amount } = request.data;

    if (!applicationId || !amount || amount <= 0) {
      throw new HttpsError("invalid-argument", "applicationIdとamount(正の整数)が必要です");
    }

    const stripe = getStripe(stripeSecretKey.value());
    const db = admin.firestore();

    try {
      // 手数料設定取得
      const configDoc = await db.doc("config/stripe").get();
      const config = configDoc.exists ? configDoc.data() : {};
      const platformFeePercent = config.platformFeePercent || 10;
      const currency = config.currency || "jpy";

      // アプリケーション情報取得
      const appDoc = await db.collection("applications").doc(applicationId).get();
      if (!appDoc.exists) {
        throw new HttpsError("not-found", "応募情報が見つかりません");
      }
      const appData = appDoc.data();

      // 職人のStripeアカウント取得
      const workerUid = appData.applicantUid;
      const workerProfile = await db.collection("profiles").doc(workerUid).get();
      const workerStripeId = workerProfile.data()?.stripeAccountId;

      if (!workerStripeId) {
        throw new HttpsError("failed-precondition", "職人のStripe口座が未設定です");
      }

      // 手数料計算
      const platformFee = Math.round(amount * (platformFeePercent / 100));
      const netAmount = amount - platformFee;

      // PaymentIntent作成
      const paymentIntent = await stripe.paymentIntents.create({
        amount: amount,
        currency: currency,
        payment_method_types: ["card"],
        transfer_data: {
          destination: workerStripeId,
        },
        application_fee_amount: platformFee,
        metadata: {
          applicationId,
          workerUid,
          adminUid: request.auth.uid,
          jobId: appData.jobId || "",
        },
      });

      // payments ドキュメント作成
      const paymentRef = await db.collection("payments").add({
        applicationId,
        jobId: appData.jobId || "",
        workerUid,
        adminUid: request.auth.uid,
        amount,
        platformFee,
        netAmount,
        stripePaymentIntentId: paymentIntent.id,
        status: "pending",
        payoutStatus: "pending",
        projectNameSnapshot: appData.projectNameSnapshot || appData.jobTitleSnapshot || "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info("PaymentIntent created", {
        paymentId: paymentRef.id,
        amount,
        platformFee,
        netAmount,
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        paymentId: paymentRef.id,
      };
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      logger.error("createPaymentIntent failed", e);
      throw new HttpsError("internal", `決済作成に失敗: ${e.message}`);
    }
  },
);

/**
 * 5. Stripe Webhook
 */
exports.handleStripeWebhook = onRequest(
  { region: REGION, secrets: [stripeSecretKey, stripeWebhookSecret] },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    const stripe = getStripe(stripeSecretKey.value());
    const sig = req.headers["stripe-signature"];

    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        sig,
        stripeWebhookSecret.value(),
      );
    } catch (e) {
      logger.error("Webhook signature verification failed", e);
      res.status(400).send(`Webhook Error: ${e.message}`);
      return;
    }

    const db = admin.firestore();

    try {
      switch (event.type) {
      case "payment_intent.succeeded": {
        const pi = event.data.object;
        const query = await db
          .collection("payments")
          .where("stripePaymentIntentId", "==", pi.id)
          .limit(1)
          .get();

        if (!query.empty) {
          await query.docs[0].ref.update({
            status: "succeeded",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logger.info("Payment succeeded", { piId: pi.id });
        }
        break;
      }

      case "payment_intent.payment_failed": {
        const pi = event.data.object;
        const query = await db
          .collection("payments")
          .where("stripePaymentIntentId", "==", pi.id)
          .limit(1)
          .get();

        if (!query.empty) {
          await query.docs[0].ref.update({
            status: "failed",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logger.info("Payment failed", { piId: pi.id });
        }
        break;
      }

      case "payout.paid": {
        const payout = event.data.object;
        logger.info("Payout paid", { payoutId: payout.id, amount: payout.amount });
        break;
      }

      default:
        logger.info("Unhandled event type", { type: event.type });
      }

      res.status(200).json({ received: true });
    } catch (e) {
      logger.error("Webhook processing failed", e);
      res.status(500).send("Internal error");
    }
  },
);

/**
 * 6. Expressダッシュボードリンク
 */
exports.getExpressDashboardLink = onCall(
  { region: REGION, secrets: [stripeSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "ログインが必要です");
    }

    const uid = request.auth.uid;
    const stripe = getStripe(stripeSecretKey.value());

    const profileRef = admin.firestore().collection("profiles").doc(uid);
    const profile = await profileRef.get();
    const accountId = profile.data()?.stripeAccountId;

    if (!accountId) {
      throw new HttpsError("not-found", "Stripeアカウントが見つかりません");
    }

    try {
      const loginLink = await stripe.accounts.createLoginLink(accountId);
      return { url: loginLink.url };
    } catch (e) {
      logger.error("getExpressDashboardLink failed", e);
      throw new HttpsError("internal", `ダッシュボードリンク生成に失敗: ${e.message}`);
    }
  },
);
