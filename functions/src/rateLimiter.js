const admin = require("firebase-admin");
const { HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

const REGION = "asia-northeast1";

/**
 * Firestore ベースのスライディングウィンドウ レート制限
 *
 * rate_limits/{identifier} コレクションで管理
 * identifier = "{type}:{uid or ip}"
 */
async function checkRateLimit(identifier, maxRequests, windowMs) {
  const db = admin.firestore();
  const now = Date.now();
  const windowStart = now - windowMs;
  const docRef = db.collection("rate_limits").doc(identifier);

  return db.runTransaction(async (transaction) => {
    const doc = await transaction.get(docRef);
    let timestamps = [];

    if (doc.exists) {
      timestamps = doc.data().timestamps || [];
    }

    // ウィンドウ外のタイムスタンプを除外
    timestamps = timestamps.filter((ts) => ts > windowStart);

    if (timestamps.length >= maxRequests) {
      return false; // レート制限超過
    }

    // 現在のタイムスタンプを追加
    timestamps.push(now);

    transaction.set(docRef, {
      timestamps,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return true; // リクエスト許可
  });
}

/**
 * レート制限チェック — 超過時に HttpsError をスロー
 */
async function enforceRateLimit(identifier, maxRequests, windowMs) {
  const allowed = await checkRateLimit(identifier, maxRequests, windowMs);
  if (!allowed) {
    logger.warn("Rate limit exceeded", { identifier, maxRequests, windowMs });
    throw new HttpsError(
      "resource-exhausted",
      "リクエスト回数の上限に達しました。しばらくしてからもう一度お試しください。",
    );
  }
}

/**
 * onRequest 用のレート制限チェック — 超過時に 429 レスポンス
 * @returns {boolean} true = 許可, false = 拒否済み（レスポンス送信済み）
 */
async function enforceRateLimitForRequest(res, identifier, maxRequests, windowMs) {
  const allowed = await checkRateLimit(identifier, maxRequests, windowMs);
  if (!allowed) {
    logger.warn("Rate limit exceeded (request)", { identifier, maxRequests, windowMs });
    res.status(429).json({
      error: "rate_limit_exceeded",
      message: "リクエスト回数の上限に達しました。しばらくしてからもう一度お試しください。",
    });
    return false;
  }
  return true;
}

// --- プリセット ---
const PRESETS = {
  auth: { maxRequests: 5, windowMs: 60 * 1000 },           // 5 req/min
  api: { maxRequests: 20, windowMs: 60 * 1000 },           // 20 req/min
  deletion: { maxRequests: 1, windowMs: 60 * 60 * 1000 },  // 1 req/hour
  payment: { maxRequests: 5, windowMs: 60 * 1000 },        // 5 req/min
};

/**
 * 期限切れのレート制限記録をクリーンアップ（1時間毎）
 */
const cleanupRateLimits = onSchedule(
  {
    schedule: "every 60 minutes",
    region: REGION,
    timeZone: "Asia/Tokyo",
  },
  async () => {
    const db = admin.firestore();
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    let totalDeleted = 0;

    const snapshot = await db
      .collection("rate_limits")
      .where("updatedAt", "<", oneHourAgo)
      .limit(500)
      .get();

    if (!snapshot.empty) {
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      totalDeleted = snapshot.size;
    }

    logger.info("Rate limits cleanup", { totalDeleted });
  },
);

module.exports = {
  checkRateLimit,
  enforceRateLimit,
  enforceRateLimitForRequest,
  PRESETS,
  cleanupRateLimits,
};
