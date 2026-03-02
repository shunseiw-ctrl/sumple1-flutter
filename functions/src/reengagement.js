const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

const MESSAGES = [
  { title: "新着案件があります", body: "あなたのエリアに新しい案件が追加されました。チェックしてみましょう！" },
  { title: "プロフィールを充実させましょう", body: "プロフィールを充実させると、企業からのスカウト率がアップします。" },
  { title: "お仕事をお探しですか？", body: "条件にマッチする案件が見つかるかもしれません。今すぐチェック！" },
];

exports.sendReengagementNotifications = onSchedule(
  {
    schedule: "every day 10:00",
    region: "asia-northeast1",
    timeZone: "Asia/Tokyo",
  },
  async () => {
    const db = admin.firestore();
    const threeDaysAgo = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000);

    try {
      const snapshot = await db
        .collection("profiles")
        .where("lastActiveAt", "<", threeDaysAgo)
        .limit(500)
        .get();

      if (snapshot.empty) {
        logger.info("No inactive users found");
        return;
      }

      let sentCount = 0;
      const msgIndex = Math.floor(Date.now() / (24 * 60 * 60 * 1000)) % MESSAGES.length;
      const message = MESSAGES[msgIndex];

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const prefs = data.notificationPreferences || {};

        if (prefs.reengagement === false) {
          continue;
        }

        const token = data.fcmToken;
        if (!token) continue;

        try {
          await admin.messaging().send({
            token,
            notification: {
              title: message.title,
              body: message.body,
            },
            data: {
              type: "reengagement",
            },
            android: {
              priority: "normal",
              notification: { channelId: "default" },
            },
            apns: {
              headers: { "apns-priority": "5" },
            },
          });
          sentCount++;
        } catch (e) {
          logger.warn("Failed to send reengagement notification", { uid: doc.id, error: e.message });
        }
      }

      logger.info(`Sent ${sentCount} reengagement notifications`);
    } catch (e) {
      logger.error("sendReengagementNotifications failed", e);
    }
  }
);
