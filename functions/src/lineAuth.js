const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");
const https = require("https");
const logger = require("firebase-functions/logger");

// In-memory stores (per instance)
const stateStore = new Map();
const tokenStore = new Map();

const LINE_CHANNEL_ID = process.env.LINE_CHANNEL_ID || "";
const LINE_CHANNEL_SECRET = process.env.LINE_CHANNEL_SECRET || "";

function httpsRequest(url, options, postData) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let data = "";
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data });
        }
      });
    });
    req.on("error", reject);
    req.setTimeout(10000, () => req.destroy(new Error("timeout")));
    if (postData) req.write(postData);
    req.end();
  });
}

function cleanupExpired(store, maxAgeMs) {
  const now = Date.now();
  for (const [key, entry] of store.entries()) {
    const ts = typeof entry === "number" ? entry : entry.createdAt;
    if (now - ts > maxAgeMs) store.delete(key);
  }
}

function isValidExchangeCode(code) {
  return typeof code === "string" && /^[a-f0-9]{64}$/.test(code);
}

const securityHeaders = {
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
};

/**
 * LINE認証リダイレクト
 */
exports.lineRedirect = onRequest(
  { region: "asia-northeast1", maxInstances: 10 },
  (req, res) => {
    if (req.method !== "GET") {
      res.status(405).set(securityHeaders).send("Method Not Allowed");
      return;
    }

    if (!LINE_CHANNEL_ID || !LINE_CHANNEL_SECRET) {
      res.status(503).set(securityHeaders).json({ error: "line_not_configured" });
      return;
    }

    const baseUrl = `https://${req.hostname}`;
    const callbackUrl = `${baseUrl}/auth/line/callback`;

    const state = crypto.randomBytes(32).toString("hex");
    stateStore.set(state, Date.now());
    cleanupExpired(stateStore, 10 * 60 * 1000);

    const params = new URLSearchParams({
      response_type: "code",
      client_id: LINE_CHANNEL_ID,
      redirect_uri: callbackUrl,
      state,
      scope: "profile openid",
    });

    res
      .set(securityHeaders)
      .redirect(`https://access.line.me/oauth2/v2.1/authorize?${params}`);
  }
);

/**
 * LINEコールバック処理
 */
exports.lineCallback = onRequest(
  { region: "asia-northeast1", maxInstances: 10 },
  async (req, res) => {
    try {
      const code = req.query.code;
      const state = req.query.state;
      const error = req.query.error;

      if (error) {
        logger.warn("LINE auth error:", error);
        res.set(securityHeaders).redirect("/#line_error=auth_denied");
        return;
      }

      if (!state || !stateStore.has(state)) {
        res.set(securityHeaders).redirect("/#line_error=invalid_state");
        return;
      }
      stateStore.delete(state);

      if (!code) {
        res.set(securityHeaders).redirect("/#line_error=no_code");
        return;
      }

      const baseUrl = `https://${req.hostname}`;
      const callbackUrl = `${baseUrl}/auth/line/callback`;

      const tokenParams = new URLSearchParams({
        grant_type: "authorization_code",
        code,
        redirect_uri: callbackUrl,
        client_id: LINE_CHANNEL_ID,
        client_secret: LINE_CHANNEL_SECRET,
      });

      const tokenRes = await httpsRequest(
        "https://api.line.me/oauth2/v2.1/token",
        { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" } },
        tokenParams.toString()
      );

      if (tokenRes.status !== 200 || !tokenRes.data.access_token) {
        logger.error("LINE token exchange failed:", tokenRes.status);
        res.set(securityHeaders).redirect("/#line_error=token_failed");
        return;
      }

      const profileRes = await httpsRequest("https://api.line.me/v2/profile", {
        method: "GET",
        headers: { Authorization: `Bearer ${tokenRes.data.access_token}` },
      });

      if (profileRes.status !== 200 || !profileRes.data.userId) {
        res.set(securityHeaders).redirect("/#line_error=profile_failed");
        return;
      }

      const lineUser = profileRes.data;
      if (!/^U[a-f0-9]{32}$/.test(lineUser.userId)) {
        res.set(securityHeaders).redirect("/#line_error=invalid_profile");
        return;
      }

      const firebaseUid = `line:${lineUser.userId}`;

      try {
        await admin.auth().getUser(firebaseUid);
      } catch (e) {
        if (e.code === "auth/user-not-found") {
          await admin.auth().createUser({
            uid: firebaseUid,
            displayName: (lineUser.displayName || "LINEユーザー").substring(0, 100),
            photoURL: lineUser.pictureUrl || null,
          });
        } else {
          throw e;
        }
      }

      await admin.auth().updateUser(firebaseUid, {
        displayName: (lineUser.displayName || "LINEユーザー").substring(0, 100),
        photoURL: lineUser.pictureUrl || null,
      });

      const customToken = await admin.auth().createCustomToken(firebaseUid, {
        provider: "line",
        lineUserId: lineUser.userId,
      });

      const exchangeCode = crypto.randomBytes(32).toString("hex");
      tokenStore.set(exchangeCode, {
        customToken,
        profile: {
          displayName: (lineUser.displayName || "").substring(0, 100),
          photoUrl: lineUser.pictureUrl || "",
          provider: "line",
        },
        createdAt: Date.now(),
      });
      cleanupExpired(tokenStore, 5 * 60 * 1000);

      res.set(securityHeaders).redirect(`/#line_code=${exchangeCode}`);
    } catch (e) {
      logger.error("LINE callback error:", e);
      res.set(securityHeaders).redirect("/#line_error=server_error");
    }
  }
);

/**
 * トークン交換
 */
exports.lineTokenExchange = onRequest(
  { region: "asia-northeast1", maxInstances: 10 },
  (req, res) => {
    res.set(securityHeaders);

    if (req.method !== "POST") {
      res.status(405).json({ error: "method_not_allowed" });
      return;
    }

    try {
      const { code } = req.body;

      if (!isValidExchangeCode(code)) {
        res.status(400).json({ error: "invalid_code_format" });
        return;
      }

      if (!tokenStore.has(code)) {
        res.status(400).json({ error: "invalid_code" });
        return;
      }

      const entry = tokenStore.get(code);
      tokenStore.delete(code);

      if (Date.now() - entry.createdAt > 5 * 60 * 1000) {
        res.status(400).json({ error: "code_expired" });
        return;
      }

      res.status(200).json({
        customToken: entry.customToken,
        profile: entry.profile,
      });
    } catch (e) {
      res.status(400).json({ error: "invalid_request" });
    }
  }
);
