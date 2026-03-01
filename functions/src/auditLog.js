const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

/**
 * 監査ログ書き込みヘルパー
 */
async function writeAuditLog(
  action,
  actorUid,
  targetCollection,
  targetDocId,
  details = {},
) {
  const db = admin.firestore();
  await db.collection("audit_logs").add({
    action,
    actorUid,
    targetCollection,
    targetDocId,
    details,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * jobs/{jobId} の create/update/delete をログ
 */
exports.onAuditJobWrite = onDocumentWritten(
  { document: "jobs/{jobId}", region: "asia-northeast1" },
  async (event) => {
    try {
      const jobId = event.params.jobId;
      const before = event.data.before?.data();
      const after = event.data.after?.data();

      if (!before && after) {
        // Created
        await writeAuditLog(
          "job_created",
          after.ownerId || "unknown",
          "jobs",
          jobId,
          { title: after.title },
        );
      } else if (before && after) {
        // Updated — 変更されたフィールドを記録
        const changedFields = {};
        for (const key of Object.keys(after)) {
          if (JSON.stringify(before[key]) !== JSON.stringify(after[key])) {
            changedFields[key] = { from: before[key], to: after[key] };
          }
        }
        if (Object.keys(changedFields).length > 0) {
          await writeAuditLog(
            "job_updated",
            after.ownerId || "unknown",
            "jobs",
            jobId,
            { changedFields },
          );
        }
      } else if (before && !after) {
        // Deleted
        await writeAuditLog(
          "job_deleted",
          before.ownerId || "unknown",
          "jobs",
          jobId,
          { title: before.title },
        );
      }
    } catch (error) {
      logger.error("onAuditJobWrite failed", error);
    }
  },
);

/**
 * applications/{appId} のステータス変更をログ
 */
exports.onAuditApplicationWrite = onDocumentWritten(
  { document: "applications/{appId}", region: "asia-northeast1" },
  async (event) => {
    try {
      const appId = event.params.appId;
      const before = event.data.before?.data();
      const after = event.data.after?.data();

      if (!before && after) {
        // Created
        await writeAuditLog(
          "application_created",
          after.applicantUid || "unknown",
          "applications",
          appId,
          { status: after.status, jobId: after.jobId },
        );
      } else if (before && after && before.status !== after.status) {
        // Status changed
        await writeAuditLog(
          "application_status_changed",
          after.adminUid || after.applicantUid || "unknown",
          "applications",
          appId,
          {
            fromStatus: before.status,
            toStatus: after.status,
            jobId: after.jobId,
          },
        );
      }
    } catch (error) {
      logger.error("onAuditApplicationWrite failed", error);
    }
  },
);

/**
 * payments/{paymentId} の作成をログ
 */
exports.onAuditPaymentCreated = onDocumentCreated(
  { document: "payments/{paymentId}", region: "asia-northeast1" },
  async (event) => {
    try {
      const paymentId = event.params.paymentId;
      const data = event.data?.data();
      if (!data) return;

      await writeAuditLog(
        "payment_created",
        data.adminUid || "unknown",
        "payments",
        paymentId,
        {
          amount: data.amount,
          workerUid: data.workerUid,
        },
      );
    } catch (error) {
      logger.error("onAuditPaymentCreated failed", error);
    }
  },
);

/**
 * ratings/{ratingId} の作成をログ
 */
exports.onAuditRatingCreated = onDocumentCreated(
  { document: "ratings/{ratingId}", region: "asia-northeast1" },
  async (event) => {
    try {
      const ratingId = event.params.ratingId;
      const data = event.data?.data();
      if (!data) return;

      await writeAuditLog(
        "rating_created",
        data.raterUid || "unknown",
        "ratings",
        ratingId,
        {
          targetUid: data.targetUid,
          stars: data.stars,
        },
      );
    } catch (error) {
      logger.error("onAuditRatingCreated failed", error);
    }
  },
);

// エクスポート（テスト用）
exports.writeAuditLog = writeAuditLog;
