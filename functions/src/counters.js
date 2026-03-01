const admin = require("firebase-admin");
const {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const { incrementDistributed } = require("./distributedCounter");

const REGION = "asia-northeast1";
const STATS_DOC = "stats/realtime";

/**
 * stats/realtime ドキュメントの指定フィールドを increment する
 * ドキュメントが存在しない場合は初期化して作成
 *
 * ※ 互換性のため残す。分散カウンタへも同時に書き込む。
 */
async function incrementStat(fields) {
  // 分散カウンタに書き込み（10万人規模対応）
  const distributedPromises = Object.entries(fields).map(
    ([key, value]) => incrementDistributed("stats", key, value).catch((e) => {
      logger.warn("distributedCounter write failed (fallback to direct)", { key, error: e.message });
    }),
  );
  await Promise.all(distributedPromises);

  // 直接書き込み（互換性: syncDistributedCounters が動くまでの即時反映）
  const ref = admin.firestore().doc(STATS_DOC);
  const update = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
  for (const [key, value] of Object.entries(fields)) {
    update[key] = admin.firestore.FieldValue.increment(value);
  }
  try {
    await ref.update(update);
  } catch (e) {
    if (e.code === 5 || e.code === "not-found") {
      const initial = {
        totalJobs: 0,
        totalApplications: 0,
        pendingApplications: 0,
        totalUsers: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      for (const [key, value] of Object.entries(fields)) {
        initial[key] = Math.max(0, value);
      }
      await ref.set(initial);
    } else {
      throw e;
    }
  }
}

// --- jobs カウンタ ---

exports.onJobCreated = onDocumentCreated(
  { document: "jobs/{jobId}", region: REGION },
  async (event) => {
    try {
      await incrementStat({ totalJobs: 1 });
      logger.info("totalJobs incremented", { jobId: event.params.jobId });
    } catch (e) {
      logger.error("onJobCreated counter failed", e);
    }
  },
);

exports.onJobDeleted = onDocumentDeleted(
  { document: "jobs/{jobId}", region: REGION },
  async (event) => {
    try {
      await incrementStat({ totalJobs: -1 });
      logger.info("totalJobs decremented", { jobId: event.params.jobId });
    } catch (e) {
      logger.error("onJobDeleted counter failed", e);
    }
  },
);

// --- applications カウンタ ---

exports.onApplicationCreated = onDocumentCreated(
  { document: "applications/{appId}", region: REGION },
  async (event) => {
    try {
      const data = event.data?.data() || {};
      const fields = { totalApplications: 1 };
      if (data.status === "applied") {
        fields.pendingApplications = 1;
      }
      await incrementStat(fields);
      logger.info("application counters updated (created)", {
        appId: event.params.appId,
      });
    } catch (e) {
      logger.error("onApplicationCreated counter failed", e);
    }
  },
);

exports.onApplicationUpdated = onDocumentWritten(
  { document: "applications/{appId}", region: REGION },
  async (event) => {
    try {
      const before = event.data?.before?.data();
      const after = event.data?.after?.data();

      if (!before || !after) return;

      const oldStatus = before.status;
      const newStatus = after.status;

      if (oldStatus === newStatus) return;

      const wasApplied = oldStatus === "applied";
      const isApplied = newStatus === "applied";

      if (wasApplied && !isApplied) {
        await incrementStat({ pendingApplications: -1 });
        logger.info("pendingApplications decremented", {
          appId: event.params.appId,
          oldStatus,
          newStatus,
        });
      } else if (!wasApplied && isApplied) {
        await incrementStat({ pendingApplications: 1 });
        logger.info("pendingApplications incremented", {
          appId: event.params.appId,
          oldStatus,
          newStatus,
        });
      }
    } catch (e) {
      logger.error("onApplicationUpdated counter failed", e);
    }
  },
);

// --- profiles カウンタ ---

exports.onProfileCreated = onDocumentCreated(
  { document: "profiles/{uid}", region: REGION },
  async (event) => {
    try {
      await incrementStat({ totalUsers: 1 });
      logger.info("totalUsers incremented", { uid: event.params.uid });
    } catch (e) {
      logger.error("onProfileCreated counter failed", e);
    }
  },
);
