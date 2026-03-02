const admin = require("firebase-admin");
const { createStripeMock } = require("./helpers/stripe-mock");

// firebase-admin をモック
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    collection: jest.fn(),
    doc: jest.fn(),
  };
  // FieldValue のモック
  firestoreMock.FieldValue = {
    serverTimestamp: jest.fn().mockReturnValue("SERVER_TIMESTAMP"),
  };
  return {
    initializeApp: jest.fn(),
    firestore: Object.assign(jest.fn(() => firestoreMock), {
      FieldValue: {
        serverTimestamp: jest.fn().mockReturnValue("SERVER_TIMESTAMP"),
      },
    }),
  };
});

jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

const logger = require("firebase-functions/logger");

describe("Stripe Functions logic", () => {
  let firestoreMock;
  let stripeMock;

  beforeEach(() => {
    jest.clearAllMocks();
    firestoreMock = admin.firestore();
    stripeMock = createStripeMock();
  });

  // --- createConnectAccount ---
  describe("createConnectAccount", () => {
    async function handleCreateConnectAccount(request) {
      if (!request.auth) {
        throw { code: "unauthenticated", message: "ログインが必要です" };
      }

      const uid = request.auth.uid;
      const email = request.data.email || "";

      const profileRef = firestoreMock.collection("profiles").doc(uid);
      const profile = await profileRef.get();
      const profileData = profile.exists ? profile.data() : {};

      if (profileData.stripeAccountId) {
        const accountLink = await stripeMock.accountLinks.create({
          account: profileData.stripeAccountId,
          type: "account_onboarding",
        });
        return { url: accountLink.url, accountId: profileData.stripeAccountId };
      }

      const account = await stripeMock.accounts.create({
        type: "express",
        country: "JP",
        email: email || undefined,
      });

      await profileRef.set({
        stripeAccountId: account.id,
        stripeAccountStatus: "pending",
      }, { merge: true });

      const accountLink = await stripeMock.accountLinks.create({
        account: account.id,
        type: "account_onboarding",
      });

      return { url: accountLink.url, accountId: account.id };
    }

    test("未認証の場合はエラー", async () => {
      await expect(
        handleCreateConnectAccount({ auth: null, data: {} }),
      ).rejects.toEqual(
        expect.objectContaining({ code: "unauthenticated" }),
      );
    });

    test("既存アカウントがある場合はリンクを再生成", async () => {
      const mockDocRef = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ stripeAccountId: "acct_existing" }),
        }),
        set: jest.fn(),
      };
      firestoreMock.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue(mockDocRef),
      });

      const result = await handleCreateConnectAccount({
        auth: { uid: "user-001" },
        data: { email: "user@test.com" },
      });

      expect(result.accountId).toBe("acct_existing");
      expect(result.url).toBeDefined();
      expect(stripeMock.accounts.create).not.toHaveBeenCalled();
    });

    test("新規アカウント作成", async () => {
      const mockDocRef = {
        get: jest.fn().mockResolvedValue({
          exists: false,
          data: () => null,
        }),
        set: jest.fn().mockResolvedValue(undefined),
      };
      firestoreMock.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue(mockDocRef),
      });

      const result = await handleCreateConnectAccount({
        auth: { uid: "user-001" },
        data: { email: "user@test.com" },
      });

      expect(stripeMock.accounts.create).toHaveBeenCalled();
      expect(result.accountId).toBe("acct_test_123");
      expect(result.url).toBeDefined();
      expect(mockDocRef.set).toHaveBeenCalledWith(
        expect.objectContaining({
          stripeAccountId: "acct_test_123",
          stripeAccountStatus: "pending",
        }),
        { merge: true },
      );
    });
  });

  // --- createAccountLink ---
  describe("createAccountLink", () => {
    async function handleCreateAccountLink(request) {
      if (!request.auth) {
        throw { code: "unauthenticated", message: "ログインが必要です" };
      }

      const uid = request.auth.uid;
      const profileRef = firestoreMock.collection("profiles").doc(uid);
      const profile = await profileRef.get();
      const accountId = profile.data()?.stripeAccountId;

      if (!accountId) {
        throw { code: "not-found", message: "Stripeアカウントが見つかりません" };
      }

      const accountLink = await stripeMock.accountLinks.create({
        account: accountId,
        type: "account_onboarding",
      });

      return { url: accountLink.url };
    }

    test("未認証の場合はエラー", async () => {
      await expect(
        handleCreateAccountLink({ auth: null, data: {} }),
      ).rejects.toEqual(
        expect.objectContaining({ code: "unauthenticated" }),
      );
    });

    test("アカウント未作成の場合はnot-found", async () => {
      const mockDocRef = {
        get: jest.fn().mockResolvedValue({
          exists: false,
          data: () => null,
        }),
      };
      firestoreMock.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue(mockDocRef),
      });

      await expect(
        handleCreateAccountLink({ auth: { uid: "user-001" }, data: {} }),
      ).rejects.toEqual(
        expect.objectContaining({ code: "not-found" }),
      );
    });
  });

  // --- getAccountStatus ---
  describe("getAccountStatus", () => {
    async function handleGetAccountStatus(request) {
      if (!request.auth) {
        throw { code: "unauthenticated", message: "ログインが必要です" };
      }

      const uid = request.auth.uid;
      const profileRef = firestoreMock.collection("profiles").doc(uid);
      const profile = await profileRef.get();
      const accountId = profile.data()?.stripeAccountId;

      if (!accountId) {
        return { status: "not_created", chargesEnabled: false, payoutsEnabled: false };
      }

      const account = await stripeMock.accounts.retrieve(accountId);
      const status = account.charges_enabled && account.payouts_enabled
        ? "active"
        : account.details_submitted
          ? "pending_verification"
          : "onboarding_incomplete";

      await profileRef.set({ stripeAccountStatus: status }, { merge: true });

      return {
        status,
        chargesEnabled: account.charges_enabled,
        payoutsEnabled: account.payouts_enabled,
        detailsSubmitted: account.details_submitted,
      };
    }

    test("アカウント未作成→not_created", async () => {
      const mockDocRef = {
        get: jest.fn().mockResolvedValue({
          exists: false,
          data: () => null,
        }),
        set: jest.fn(),
      };
      firestoreMock.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue(mockDocRef),
      });

      const result = await handleGetAccountStatus({
        auth: { uid: "user-001" },
        data: {},
      });

      expect(result.status).toBe("not_created");
      expect(result.chargesEnabled).toBe(false);
    });

    test("active (charges+payouts enabled)", async () => {
      const mockDocRef = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ stripeAccountId: "acct_test_123" }),
        }),
        set: jest.fn(),
      };
      firestoreMock.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue(mockDocRef),
      });

      stripeMock.accounts.retrieve.mockResolvedValue({
        charges_enabled: true,
        payouts_enabled: true,
        details_submitted: true,
      });

      const result = await handleGetAccountStatus({
        auth: { uid: "user-001" },
        data: {},
      });

      expect(result.status).toBe("active");
      expect(result.chargesEnabled).toBe(true);
      expect(result.payoutsEnabled).toBe(true);
    });

    test("pending_verification (details_submitted only)", async () => {
      const mockDocRef = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ stripeAccountId: "acct_test_123" }),
        }),
        set: jest.fn(),
      };
      firestoreMock.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue(mockDocRef),
      });

      stripeMock.accounts.retrieve.mockResolvedValue({
        charges_enabled: false,
        payouts_enabled: false,
        details_submitted: true,
      });

      const result = await handleGetAccountStatus({
        auth: { uid: "user-001" },
        data: {},
      });

      expect(result.status).toBe("pending_verification");
    });
  });

  // --- createPaymentIntent ---
  describe("createPaymentIntent", () => {
    async function handleCreatePaymentIntent(request) {
      if (!request.auth) {
        throw { code: "unauthenticated", message: "ログインが必要です" };
      }

      const { applicationId, amount } = request.data;

      if (!applicationId || !amount || amount <= 0) {
        throw { code: "invalid-argument", message: "applicationIdとamount(正の整数)が必要です" };
      }

      const db = firestoreMock;

      // 手数料設定取得
      const configDoc = await db.doc("config/stripe").get();
      const config = configDoc.exists ? configDoc.data() : {};
      const platformFeePercent = config.platformFeePercent || 10;

      // アプリケーション情報取得
      const appDoc = await db.collection("applications").doc(applicationId).get();
      if (!appDoc.exists) {
        throw { code: "not-found", message: "応募情報が見つかりません" };
      }
      const appData = appDoc.data();

      // 職人のStripeアカウント取得
      const workerUid = appData.applicantUid;
      const workerProfile = await db.collection("profiles").doc(workerUid).get();
      const workerStripeId = workerProfile.data()?.stripeAccountId;

      if (!workerStripeId) {
        throw { code: "failed-precondition", message: "職人のStripe口座が未設定です" };
      }

      // 手数料計算
      const platformFee = Math.round(amount * (platformFeePercent / 100));
      const netAmount = amount - platformFee;

      // PaymentIntent作成
      const paymentIntent = await stripeMock.paymentIntents.create({
        amount,
        application_fee_amount: platformFee,
        transfer_data: { destination: workerStripeId },
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        platformFee,
        netAmount,
      };
    }

    test("未認証の場合はエラー", async () => {
      await expect(
        handleCreatePaymentIntent({ auth: null, data: {} }),
      ).rejects.toEqual(
        expect.objectContaining({ code: "unauthenticated" }),
      );
    });

    test("不正引数（amount=0）の場合はエラー", async () => {
      await expect(
        handleCreatePaymentIntent({
          auth: { uid: "admin-001" },
          data: { applicationId: "app-001", amount: 0 },
        }),
      ).rejects.toEqual(
        expect.objectContaining({ code: "invalid-argument" }),
      );
    });

    test("不正引数（applicationId未指定）の場合はエラー", async () => {
      await expect(
        handleCreatePaymentIntent({
          auth: { uid: "admin-001" },
          data: { amount: 10000 },
        }),
      ).rejects.toEqual(
        expect.objectContaining({ code: "invalid-argument" }),
      );
    });

    test("口座未設定の場合はfailed-precondition", async () => {
      // config/stripe
      firestoreMock.doc.mockReturnValue({
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ platformFeePercent: 10, currency: "jpy" }),
        }),
      });

      // applications
      const appDocRef = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            applicantUid: "worker-001",
            jobId: "job-001",
          }),
        }),
      };

      // profiles (Stripe未設定)
      const workerDocRef = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ stripeAccountId: null }),
        }),
      };

      firestoreMock.collection.mockImplementation((col) => ({
        doc: jest.fn().mockImplementation(() => {
          if (col === "applications") return appDocRef;
          if (col === "profiles") return workerDocRef;
          return appDocRef;
        }),
      }));

      await expect(
        handleCreatePaymentIntent({
          auth: { uid: "admin-001" },
          data: { applicationId: "app-001", amount: 10000 },
        }),
      ).rejects.toEqual(
        expect.objectContaining({ code: "failed-precondition" }),
      );
    });

    test("正常: 手数料計算の検証 (10%)", async () => {
      firestoreMock.doc.mockReturnValue({
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ platformFeePercent: 10, currency: "jpy" }),
        }),
      });

      const appDocRef = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            applicantUid: "worker-001",
            jobId: "job-001",
            projectNameSnapshot: "テスト案件",
          }),
        }),
      };

      const workerDocRef = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ stripeAccountId: "acct_worker_123" }),
        }),
      };

      firestoreMock.collection.mockImplementation((col) => ({
        doc: jest.fn().mockImplementation(() => {
          if (col === "applications") return appDocRef;
          if (col === "profiles") return workerDocRef;
          return appDocRef;
        }),
      }));

      const result = await handleCreatePaymentIntent({
        auth: { uid: "admin-001" },
        data: { applicationId: "app-001", amount: 15000 },
      });

      expect(result.platformFee).toBe(1500);
      expect(result.netAmount).toBe(13500);
      expect(result.paymentIntentId).toBe("pi_test_123");
      expect(result.clientSecret).toBe("pi_test_123_secret");
      expect(stripeMock.paymentIntents.create).toHaveBeenCalledWith(
        expect.objectContaining({
          amount: 15000,
          application_fee_amount: 1500,
          transfer_data: { destination: "acct_worker_123" },
        }),
      );
    });
  });

  // --- handleStripeWebhook ---
  describe("handleStripeWebhook", () => {
    async function handleWebhook(req, res) {
      if (req.method !== "POST") {
        res.status(405).send("Method not allowed");
        return;
      }

      const sig = req.headers["stripe-signature"];
      let event;
      try {
        event = stripeMock.webhooks.constructEvent(req.rawBody, sig, "webhook_secret");
      } catch (e) {
        res.status(400).send(`Webhook Error: ${e.message}`);
        return;
      }

      const db = firestoreMock;

      switch (event.type) {
      case "payment_intent.succeeded": {
        const pi = event.data.object;
        const query = await db.collection("payments").where("stripePaymentIntentId", "==", pi.id).limit(1).get();
        if (!query.empty) {
          await query.docs[0].ref.update({ status: "succeeded" });
        }
        break;
      }
      case "payment_intent.payment_failed": {
        const pi = event.data.object;
        const query = await db.collection("payments").where("stripePaymentIntentId", "==", pi.id).limit(1).get();
        if (!query.empty) {
          await query.docs[0].ref.update({ status: "failed" });
        }
        break;
      }
      default:
        logger.info("Unhandled event type", { type: event.type });
      }

      res.status(200).json({ received: true });
    }

    function createMockRes() {
      const res = {
        statusCode: null,
        body: null,
        status: jest.fn().mockImplementation((code) => {
          res.statusCode = code;
          return res;
        }),
        send: jest.fn().mockImplementation((body) => {
          res.body = body;
        }),
        json: jest.fn().mockImplementation((body) => {
          res.body = body;
        }),
      };
      return res;
    }

    test("POST以外→405", async () => {
      const res = createMockRes();
      await handleWebhook({ method: "GET", headers: {} }, res);
      expect(res.statusCode).toBe(405);
    });

    test("不正署名→400", async () => {
      const res = createMockRes();
      await handleWebhook({
        method: "POST",
        headers: { "stripe-signature": "invalid" },
        rawBody: "{}",
      }, res);
      expect(res.statusCode).toBe(400);
    });

    test("payment_intent.succeeded: ステータス更新", async () => {
      const updateFn = jest.fn().mockResolvedValue(undefined);
      const mockQuery = {
        empty: false,
        docs: [{ ref: { update: updateFn } }],
      };

      firestoreMock.collection.mockReturnValue({
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(mockQuery),
          }),
        }),
      });

      stripeMock.webhooks.constructEvent.mockReturnValue({
        type: "payment_intent.succeeded",
        data: { object: { id: "pi_test_123" } },
      });

      const res = createMockRes();
      await handleWebhook({
        method: "POST",
        headers: { "stripe-signature": "valid_sig" },
        rawBody: "{}",
      }, res);

      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual({ received: true });
      expect(updateFn).toHaveBeenCalledWith(
        expect.objectContaining({ status: "succeeded" }),
      );
    });

    test("payment_intent.payment_failed: ステータスをfailedに更新", async () => {
      const updateFn = jest.fn().mockResolvedValue(undefined);
      const mockQuery = {
        empty: false,
        docs: [{ ref: { update: updateFn } }],
      };

      firestoreMock.collection.mockReturnValue({
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(mockQuery),
          }),
        }),
      });

      stripeMock.webhooks.constructEvent.mockReturnValue({
        type: "payment_intent.payment_failed",
        data: { object: { id: "pi_test_456" } },
      });

      const res = createMockRes();
      await handleWebhook({
        method: "POST",
        headers: { "stripe-signature": "valid_sig" },
        rawBody: "{}",
      }, res);

      expect(res.statusCode).toBe(200);
      expect(updateFn).toHaveBeenCalledWith(
        expect.objectContaining({ status: "failed" }),
      );
    });

    test("payout.paid → payoutStatusをpaidに更新", async () => {
      const updateFn = jest.fn().mockResolvedValue(undefined);
      const paymentDocs = [
        {
          ref: { update: updateFn },
          data: () => ({
            workerUid: "worker-001",
            payoutStatus: "pending",
          }),
        },
      ];

      const profileDocRef = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ stripeAccountId: "acct_worker_123" }),
        }),
      };

      firestoreMock.collection.mockImplementation((col) => {
        if (col === "payments") {
          return {
            where: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({ docs: paymentDocs }),
            }),
          };
        }
        if (col === "profiles") {
          return { doc: jest.fn().mockReturnValue(profileDocRef) };
        }
        return {};
      });

      // payout.paidイベントハンドラのロジック再現
      const payout = { id: "po_test_123", amount: 50000, destination: "acct_worker_123" };
      const destinationAccountId = payout.destination;

      if (destinationAccountId) {
        const paymentsQuery = await firestoreMock.collection("payments")
          .where("payoutStatus", "!=", "paid").get();
        for (const paymentDoc of paymentsQuery.docs) {
          const paymentData = paymentDoc.data();
          if (paymentData.workerUid) {
            const workerProfile = await firestoreMock.collection("profiles").doc(paymentData.workerUid).get();
            const workerStripeId = workerProfile.data()?.stripeAccountId;
            if (workerStripeId === destinationAccountId && paymentData.payoutStatus !== "paid") {
              await paymentDoc.ref.update({ payoutStatus: "paid" });
            }
          }
        }
      }

      expect(updateFn).toHaveBeenCalledWith(expect.objectContaining({ payoutStatus: "paid" }));
    });

    test("payout.paid → 該当Stripeアカウントの支払いのみ更新", async () => {
      const updateFn1 = jest.fn().mockResolvedValue(undefined);
      const updateFn2 = jest.fn().mockResolvedValue(undefined);
      const paymentDocs = [
        {
          ref: { update: updateFn1 },
          data: () => ({ workerUid: "worker-001", payoutStatus: "pending" }),
        },
        {
          ref: { update: updateFn2 },
          data: () => ({ workerUid: "worker-002", payoutStatus: "pending" }),
        },
      ];

      firestoreMock.collection.mockImplementation((col) => {
        if (col === "payments") {
          return {
            where: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({ docs: paymentDocs }),
            }),
          };
        }
        if (col === "profiles") {
          return {
            doc: jest.fn().mockImplementation((uid) => ({
              get: jest.fn().mockResolvedValue({
                exists: true,
                data: () => ({
                  stripeAccountId: uid === "worker-001" ? "acct_target" : "acct_other",
                }),
              }),
            })),
          };
        }
        return {};
      });

      const destinationAccountId = "acct_target";
      const paymentsQuery = await firestoreMock.collection("payments")
        .where("payoutStatus", "!=", "paid").get();
      for (const paymentDoc of paymentsQuery.docs) {
        const paymentData = paymentDoc.data();
        if (paymentData.workerUid) {
          const workerProfile = await firestoreMock.collection("profiles").doc(paymentData.workerUid).get();
          const workerStripeId = workerProfile.data()?.stripeAccountId;
          if (workerStripeId === destinationAccountId && paymentData.payoutStatus !== "paid") {
            await paymentDoc.ref.update({ payoutStatus: "paid" });
          }
        }
      }

      expect(updateFn1).toHaveBeenCalledWith(expect.objectContaining({ payoutStatus: "paid" }));
      expect(updateFn2).not.toHaveBeenCalled();
    });

    test("payout.paid → 既にpaidの支払いは無視", async () => {
      const updateFn = jest.fn().mockResolvedValue(undefined);
      const paymentDocs = [
        {
          ref: { update: updateFn },
          data: () => ({ workerUid: "worker-001", payoutStatus: "paid" }),
        },
      ];

      firestoreMock.collection.mockImplementation((col) => {
        if (col === "payments") {
          return {
            where: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({ docs: paymentDocs }),
            }),
          };
        }
        if (col === "profiles") {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({
                exists: true,
                data: () => ({ stripeAccountId: "acct_target" }),
              }),
            }),
          };
        }
        return {};
      });

      const destinationAccountId = "acct_target";
      const paymentsQuery = await firestoreMock.collection("payments")
        .where("payoutStatus", "!=", "paid").get();
      for (const paymentDoc of paymentsQuery.docs) {
        const paymentData = paymentDoc.data();
        if (paymentData.workerUid) {
          const workerProfile = await firestoreMock.collection("profiles").doc(paymentData.workerUid).get();
          const workerStripeId = workerProfile.data()?.stripeAccountId;
          if (workerStripeId === destinationAccountId && paymentData.payoutStatus !== "paid") {
            await paymentDoc.ref.update({ payoutStatus: "paid" });
          }
        }
      }

      expect(updateFn).not.toHaveBeenCalled();
    });

    test("不明なイベントタイプはログのみ", async () => {
      stripeMock.webhooks.constructEvent.mockReturnValue({
        type: "unknown.event",
        data: { object: {} },
      });

      const res = createMockRes();
      await handleWebhook({
        method: "POST",
        headers: { "stripe-signature": "valid_sig" },
        rawBody: "{}",
      }, res);

      expect(res.statusCode).toBe(200);
      expect(logger.info).toHaveBeenCalledWith(
        "Unhandled event type",
        expect.objectContaining({ type: "unknown.event" }),
      );
    });
  });
});
