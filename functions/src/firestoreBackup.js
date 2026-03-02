const admin = require("firebase-admin");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

const REGION = "asia-northeast1";

/**
 * バックアップ対象コレクション
 */
const BACKUP_COLLECTIONS = [
  "profiles",
  "jobs",
  "applications",
  "earnings",
  "payments",
  "ratings",
  "chats",
  "notifications",
  "contacts",
  "config",
  "audit_logs",
  "favorites",
];

/**
 * 毎日 03:00 JST に Firestore を GCS にエクスポート
 */
const dailyFirestoreBackup = onSchedule(
  {
    schedule: "0 3 * * *",
    region: REGION,
    timeZone: "Asia/Tokyo",
    retryCount: 3,
  },
  async () => {
    const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
    const timestamp = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
    const bucketName = `${projectId}-firestore-backups`;
    const outputUri = `gs://${bucketName}/${timestamp}`;

    try {
      const client = new admin.firestore.v1.FirestoreAdminClient();
      const databaseName = client.databasePath(projectId, "(default)");

      const collectionIds = BACKUP_COLLECTIONS;

      const [response] = await client.exportDocuments({
        name: databaseName,
        outputUriPrefix: outputUri,
        collectionIds,
      });

      logger.info("Firestore backup started", {
        operationName: response.name,
        outputUri,
        collections: collectionIds.length,
      });

      // 監査ログ記録
      await admin.firestore().collection("audit_logs").add({
        action: "firestore_backup",
        actorUid: "system",
        targetCollection: "all",
        targetDocId: timestamp,
        details: {
          outputUri,
          collections: collectionIds,
          operationName: response.name || "unknown",
        },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info("Firestore backup audit log recorded", { timestamp });
    } catch (error) {
      logger.error("Firestore backup failed", {
        error: error.message,
        projectId,
      });
      throw error;
    }
  },
);

module.exports = {
  dailyFirestoreBackup,
  BACKUP_COLLECTIONS,
};
