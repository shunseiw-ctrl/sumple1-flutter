const admin = require("firebase-admin");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

const REGION = "asia-northeast1";
const NUM_SHARDS = 10;

/**
 * 分散カウンタにインクリメント書き込み
 *
 * @param {string} counterName - カウンタ名 (例: "stats")
 * @param {string} field - フィールド名 (例: "totalJobs")
 * @param {number} delta - 増減値
 */
async function incrementDistributed(counterName, field, delta) {
  const shardId = Math.floor(Math.random() * NUM_SHARDS);
  const shardRef = admin.firestore()
    .collection("counters")
    .doc(counterName)
    .collection("shards")
    .doc(String(shardId));

  await shardRef.set(
    {
      [field]: admin.firestore.FieldValue.increment(delta),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

/**
 * 分散カウンタの全シャードを集計して合計値を返す
 *
 * @param {string} counterName - カウンタ名
 * @param {string} field - フィールド名
 * @returns {Promise<number>} 合計値
 */
async function getDistributedCount(counterName, field) {
  const shardsSnap = await admin.firestore()
    .collection("counters")
    .doc(counterName)
    .collection("shards")
    .get();

  let total = 0;
  shardsSnap.docs.forEach((doc) => {
    const value = doc.data()[field];
    if (typeof value === "number") {
      total += value;
    }
  });
  return total;
}

/**
 * 分散カウンタを初期化（シャードドキュメントを事前作成）
 *
 * @param {string} counterName - カウンタ名
 * @param {Object} initialFields - 初期フィールド (例: { totalJobs: 0, totalUsers: 0 })
 */
async function initializeShards(counterName, initialFields) {
  const batch = admin.firestore().batch();
  for (let i = 0; i < NUM_SHARDS; i++) {
    const shardRef = admin.firestore()
      .collection("counters")
      .doc(counterName)
      .collection("shards")
      .doc(String(i));
    batch.set(shardRef, {
      ...initialFields,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  logger.info("Distributed counter shards initialized", { counterName, numShards: NUM_SHARDS });
}

/**
 * 分散カウンタの全シャード合計を stats/realtime に同期 (5分おき)
 *
 * admin_home_page は既に stats/realtime を読んでいるため、
 * この関数で同期するだけで UI 側の変更は不要。
 */
const syncDistributedCounters = onSchedule(
  {
    schedule: "every 5 minutes",
    region: REGION,
    timeZone: "Asia/Tokyo",
  },
  async () => {
    try {
      const fields = ["totalJobs", "totalApplications", "pendingApplications", "totalUsers"];
      const countsMap = {};

      for (const field of fields) {
        countsMap[field] = await getDistributedCount("stats", field);
      }

      await admin.firestore().doc("stats/realtime").set(
        {
          ...countsMap,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          syncedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      logger.info("Distributed counters synced to stats/realtime", countsMap);
    } catch (e) {
      logger.error("syncDistributedCounters failed", e);
    }
  },
);

module.exports = {
  incrementDistributed,
  getDistributedCount,
  initializeShards,
  syncDistributedCounters,
  NUM_SHARDS,
};
