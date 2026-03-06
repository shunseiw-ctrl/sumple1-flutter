const admin = require("firebase-admin");
const crypto = require("crypto");
const https = require("https");
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

const REGION = "asia-northeast1";
const STATE_TTL_MS = 10 * 60 * 1000; // 10分
const TOKEN_TTL_MS = 5 * 60 * 1000; // 5分
const CLEANUP_AGE_MS = 30 * 60 * 1000; // 30分

/**
 * HTTPS request ヘルパー
 */
function httpsRequest(url, options, postData) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let data = "";
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (_) {
          resolve({ status: res.statusCode, data });
        }
      });
    });
    req.on("error", reject);
    if (postData) req.write(postData);
    req.end();
  });
}

/**
 * LINE OAuth 開始 — CSRF state を Firestore に保存してリダイレクト
 */
exports.lineAuthStart = onRequest(
  { region: REGION, cors: false },
  async (req, res) => {
    try {
      const lineChannelId = process.env.LINE_CHANNEL_ID || "";
      if (!lineChannelId) {
        logger.error("LINE_CHANNEL_ID not configured");
        res.status(500).send("Server configuration error");
        return;
      }

      const state = crypto.randomBytes(32).toString("hex");
      const platform = req.query.platform || "web";
      const callbackUrl = `${req.protocol}://${req.hostname}/auth/line/callback`;

      // Firestore に state を保存
      await admin.firestore().collection("line_auth_states").doc(state).set({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + STATE_TTL_MS),
        callbackUrl,
        platform,
      });

      const params = new URLSearchParams({
        response_type: "code",
        client_id: lineChannelId,
        redirect_uri: callbackUrl,
        state,
        scope: "profile openid",
      });

      const lineAuthUrl = `https://access.line.me/oauth2/v2.1/authorize?${params.toString()}`;
      res.redirect(302, lineAuthUrl);
    } catch (e) {
      logger.error("lineAuthStart failed", e);
      res.status(500).send("Internal Server Error");
    }
  },
);

/**
 * LINE ユーザーの Firebase Auth ユーザーを解決（リンク済みチェック → 作成/更新）
 * lineAuthCallback と lineAuthVerifyToken で共有
 * @returns {{ firebaseUid: string }}
 */
async function resolveFirebaseUser(lineUser) {
  let firebaseUid = `line:${lineUser.userId}`;

  const linkedDoc = await admin.firestore()
    .collection("line_linked_accounts")
    .doc(lineUser.userId)
    .get();

  if (linkedDoc.exists) {
    firebaseUid = linkedDoc.data().firebaseUid;
    logger.info("Using linked account", { lineUserId: lineUser.userId, firebaseUid });
  } else {
    // Firebase Auth ユーザー作成/更新
    try {
      await admin.auth().getUser(firebaseUid);
    } catch (e) {
      if (e.code === "auth/user-not-found") {
        await admin.auth().createUser({
          uid: firebaseUid,
          displayName: lineUser.displayName || "LINEユーザー",
          photoURL: lineUser.pictureUrl || undefined,
        });
        logger.info("Created new Firebase user for LINE", { uid: firebaseUid });
      } else {
        throw e;
      }
    }

    await admin.auth().updateUser(firebaseUid, {
      displayName: lineUser.displayName || "LINEユーザー",
      photoURL: lineUser.pictureUrl || undefined,
    });
  }

  return { firebaseUid };
}

/**
 * LINE ユーザー用のカスタムトークンとプロフィールを生成
 */
async function createLineTokenAndProfile(lineUser) {
  const { firebaseUid } = await resolveFirebaseUser(lineUser);

  const customToken = await admin.auth().createCustomToken(firebaseUid, {
    provider: "line",
    lineUserId: lineUser.userId,
  });

  const profile = {
    displayName: lineUser.displayName || "",
    photoUrl: lineUser.pictureUrl || "",
    provider: "line",
  };

  return { firebaseUid, customToken, profile };
}

/**
 * LINE OAuth コールバック — token取得→Firebase カスタムトークン生成→交換コード発行
 */
exports.lineAuthCallback = onRequest(
  { region: REGION, cors: false },
  async (req, res) => {
    try {
      const code = req.query.code;
      const state = req.query.state;
      const error = req.query.error;

      // ベースURL（フロントエンドリダイレクト用）
      const baseUrl = `${req.protocol}://${req.hostname}`;

      if (error) {
        logger.warn("LINE auth error", { error, description: req.query.error_description });
        res.redirect(302, `${baseUrl}/#line_error=auth_denied`);
        return;
      }

      if (!state) {
        res.redirect(302, `${baseUrl}/#line_error=invalid_state`);
        return;
      }

      // Firestore から state を検証
      const stateRef = admin.firestore().collection("line_auth_states").doc(state);
      const stateDoc = await stateRef.get();

      if (!stateDoc.exists) {
        logger.warn("Invalid or expired state", { state: state.substring(0, 8) });
        res.redirect(302, `${baseUrl}/#line_error=invalid_state`);
        return;
      }

      const stateData = stateDoc.data();
      const expiresAt = stateData.expiresAt?.toDate ? stateData.expiresAt.toDate() : new Date(stateData.expiresAt);
      if (Date.now() > expiresAt.getTime()) {
        await stateRef.delete();
        res.redirect(302, `${baseUrl}/#line_error=state_expired`);
        return;
      }

      // state を消費（ワンタイム）
      await stateRef.delete();

      if (!code) {
        res.redirect(302, `${baseUrl}/#line_error=no_code`);
        return;
      }

      // LINE token 取得
      const lineChannelId = process.env.LINE_CHANNEL_ID || "";
      const lineChannelSecret = process.env.LINE_CHANNEL_SECRET || "";
      const callbackUrl = stateData.callbackUrl || `${baseUrl}/auth/line/callback`;

      const tokenParams = new URLSearchParams({
        grant_type: "authorization_code",
        code,
        redirect_uri: callbackUrl,
        client_id: lineChannelId,
        client_secret: lineChannelSecret,
      });

      const tokenRes = await httpsRequest("https://api.line.me/oauth2/v2.1/token", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
      }, tokenParams.toString());

      if (tokenRes.status !== 200 || !tokenRes.data.access_token) {
        logger.error("LINE token exchange failed", { status: tokenRes.status });
        res.redirect(302, `${baseUrl}/#line_error=token_failed`);
        return;
      }

      const accessToken = tokenRes.data.access_token;

      // LINE プロフィール取得
      const profileRes = await httpsRequest("https://api.line.me/v2/profile", {
        method: "GET",
        headers: { Authorization: `Bearer ${accessToken}` },
      });

      if (profileRes.status !== 200 || !profileRes.data.userId) {
        logger.error("LINE profile fetch failed", { status: profileRes.status });
        res.redirect(302, `${baseUrl}/#line_error=profile_failed`);
        return;
      }

      const lineUser = profileRes.data;

      // ヘルパーでユーザー解決 + カスタムトークン生成
      const { firebaseUid, customToken, profile } = await createLineTokenAndProfile(lineUser);

      // 交換コードを Firestore に保存
      const exchangeCode = crypto.randomBytes(32).toString("hex");
      await admin.firestore().collection("line_auth_tokens").doc(exchangeCode).set({
        customToken,
        profile,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + TOKEN_TTL_MS),
      });

      logger.info("LINE login successful", { uid: firebaseUid });

      // モバイルの場合はUniversal Linkパスにリダイレクト
      const statePlatform = stateData.platform || "web";
      if (statePlatform === "mobile") {
        res.redirect(302, `${baseUrl}/line-callback?code=${exchangeCode}`);
      } else {
        res.redirect(302, `${baseUrl}/#line_code=${exchangeCode}`);
      }
    } catch (e) {
      logger.error("lineAuthCallback failed", e);
      const baseUrl = `${req.protocol}://${req.hostname}`;
      res.redirect(302, `${baseUrl}/#line_error=server_error`);
    }
  },
);

/**
 * LINE 交換コード → customToken + profile を返却
 */
exports.lineAuthExchange = onRequest(
  { region: REGION, cors: true },
  async (req, res) => {
    try {
      if (req.method !== "POST") {
        res.status(405).json({ error: "method_not_allowed" });
        return;
      }

      // レート制限（IP ベース）
      const { enforceRateLimitForRequest, PRESETS } = require("./rateLimiter");
      const clientIp = req.ip || req.headers["x-forwarded-for"] || "unknown";
      const allowed = await enforceRateLimitForRequest(
        res,
        `auth:${clientIp}`,
        PRESETS.auth.maxRequests,
        PRESETS.auth.windowMs,
      );
      if (!allowed) return;

      const { code } = req.body || {};
      if (!code) {
        res.status(400).json({ error: "missing_code" });
        return;
      }

      // Firestore から交換コードを検証
      const tokenRef = admin.firestore().collection("line_auth_tokens").doc(code);
      const tokenDoc = await tokenRef.get();

      if (!tokenDoc.exists) {
        res.status(400).json({ error: "invalid_code" });
        return;
      }

      const tokenData = tokenDoc.data();

      // 交換コードを消費（ワンタイム）
      await tokenRef.delete();

      // 有効期限チェック
      const expiresAt = tokenData.expiresAt?.toDate ? tokenData.expiresAt.toDate() : new Date(tokenData.expiresAt);
      if (Date.now() > expiresAt.getTime()) {
        res.status(400).json({ error: "code_expired" });
        return;
      }

      res.status(200).json({
        customToken: tokenData.customToken,
        profile: tokenData.profile,
      });
    } catch (e) {
      logger.error("lineAuthExchange failed", e);
      res.status(500).json({ error: "server_error" });
    }
  },
);

/**
 * LINE SDK ネイティブログインのアクセストークンを検証し、Firebase custom token を返す
 */
exports.lineAuthVerifyToken = onRequest(
  { region: REGION, cors: true },
  async (req, res) => {
    try {
      if (req.method !== "POST") {
        res.status(405).json({ error: "method_not_allowed" });
        return;
      }

      // レート制限（IP ベース）
      const { enforceRateLimitForRequest, PRESETS } = require("./rateLimiter");
      const clientIp = req.ip || req.headers["x-forwarded-for"] || "unknown";
      const allowed = await enforceRateLimitForRequest(
        res,
        `auth:${clientIp}`,
        PRESETS.auth.maxRequests,
        PRESETS.auth.windowMs,
      );
      if (!allowed) return;

      const { accessToken } = req.body || {};
      if (!accessToken) {
        res.status(400).json({ error: "missing_access_token" });
        return;
      }

      const lineChannelId = process.env.LINE_CHANNEL_ID || "";

      // LINE Verify API でトークン検証
      const verifyRes = await httpsRequest(
        `https://api.line.me/oauth2/v2.1/verify?access_token=${encodeURIComponent(accessToken)}`,
        { method: "GET" },
      );

      if (verifyRes.status !== 200) {
        logger.warn("LINE token verification failed", { status: verifyRes.status });
        res.status(401).json({ error: "invalid_token" });
        return;
      }

      // Channel ID 一致確認
      if (verifyRes.data.client_id !== lineChannelId) {
        logger.warn("LINE channel ID mismatch", {
          expected: lineChannelId,
          got: verifyRes.data.client_id,
        });
        res.status(401).json({ error: "channel_mismatch" });
        return;
      }

      // トークン期限切れチェック
      if (verifyRes.data.expires_in <= 0) {
        res.status(401).json({ error: "token_expired" });
        return;
      }

      // LINE Profile API でユーザー情報取得
      const profileRes = await httpsRequest("https://api.line.me/v2/profile", {
        method: "GET",
        headers: { Authorization: `Bearer ${accessToken}` },
      });

      if (profileRes.status !== 200 || !profileRes.data.userId) {
        logger.error("LINE profile fetch failed", { status: profileRes.status });
        res.status(500).json({ error: "profile_failed" });
        return;
      }

      const lineUser = profileRes.data;

      // ヘルパーでユーザー解決 + カスタムトークン生成
      const { firebaseUid, customToken, profile } = await createLineTokenAndProfile(lineUser);

      logger.info("LINE SDK verify-token successful", { uid: firebaseUid });

      res.status(200).json({ customToken, profile });
    } catch (e) {
      logger.error("lineAuthVerifyToken failed", e);
      res.status(500).json({ error: "server_error" });
    }
  },
);

/**
 * 期限切れの LINE 認証ドキュメントを定期削除 (30分おき)
 */
exports.cleanupExpiredLineAuthDocs = onSchedule(
  {
    schedule: "every 30 minutes",
    region: REGION,
    timeZone: "Asia/Tokyo",
  },
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const cutoff = new Date(now.getTime() - CLEANUP_AGE_MS);
    let totalDeleted = 0;

    // line_auth_states のクリーンアップ
    const statesSnap = await db.collection("line_auth_states")
      .where("expiresAt", "<", cutoff)
      .limit(500)
      .get();

    const batch1 = db.batch();
    statesSnap.docs.forEach((doc) => batch1.delete(doc.ref));
    if (!statesSnap.empty) {
      await batch1.commit();
      totalDeleted += statesSnap.size;
    }

    // line_auth_tokens のクリーンアップ
    const tokensSnap = await db.collection("line_auth_tokens")
      .where("expiresAt", "<", cutoff)
      .limit(500)
      .get();

    const batch2 = db.batch();
    tokensSnap.docs.forEach((doc) => batch2.delete(doc.ref));
    if (!tokensSnap.empty) {
      await batch2.commit();
      totalDeleted += tokensSnap.size;
    }

    logger.info("Cleaned up expired LINE auth docs", { totalDeleted });
  },
);
