const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

/**
 * notifications/{notifId} 作成時に FCM プッシュ通知を送信
 *
 * notifications ドキュメントの想定フィールド:
 * - targetUid: string (通知対象ユーザーUID)
 * - title: string
 * - body: string
 * - type: string
 * - data: map (任意)
 * - read: bool
 * - createdAt: Timestamp
 */
exports.onNotificationCreated = onDocumentCreated(
  {
    document: "notifications/{notifId}",
    region: "asia-northeast1",
  },
  async (event) => {
    try {
      const snap = event.data;
      if (!snap) {
        logger.warn("No snapshot in event");
        return;
      }

      const notifId = event.params.notifId;
      const data = snap.data() || {};

      const targetUid = data.targetUid;
      const title = data.title || "ALBAWORK";
      const body = data.body || "";
      const type = data.type || "general";

      if (!targetUid) {
        logger.warn("Missing targetUid on notifications doc", { notifId });
        return;
      }

      // profiles/{targetUid} から FCM token を取得
      const profileRef = admin
        .firestore()
        .collection("profiles")
        .doc(targetUid);
      const profileSnap = await profileRef.get();

      if (!profileSnap.exists) {
        logger.warn("Profile not found", { targetUid, notifId });
        return;
      }

      const profile = profileSnap.data() || {};
      const token = profile.fcmToken;

      if (!token) {
        logger.warn("No fcmToken on profile", { targetUid, notifId });
        return;
      }

      const message = {
        token,
        notification: { title, body },
        data: {
          type: String(type),
          notificationId: String(notifId),
        },
        android: {
          priority: "high",
          notification: {
            channelId: "default",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
        },
      };

      const res = await admin.messaging().send(message);
      logger.info("FCM sent for notification", { res, targetUid, notifId });
    } catch (e) {
      logger.error("onNotificationCreated failed", e);
    }
  },
);
