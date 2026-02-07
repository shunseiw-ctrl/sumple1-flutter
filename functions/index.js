const admin = require("firebase-admin");

// v2 (firebase-functions v5+) の書き方
const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

admin.initializeApp();

// コスト制御（任意）
setGlobalOptions({ maxInstances: 10 });

/**
 * earnings/{earningId} 作成時に、profiles/{uid}.fcmToken に通知を送る
 *
 * 前提（Flutter側で実装）:
 * - profiles/{uid}.fcmToken を端末起動/ログイン後に保存していること
 *
 * earnings ドキュメントの想定フィールド:
 * - uid: string (支払対象ユーザーUID)
 * - amount: int
 * - payoutConfirmedAt: Timestamp
 * - projectNameSnapshot: string
 */
exports.onEarningCreated = onDocumentCreated(
  {
    document: "earnings/{earningId}",
    region: "asia-northeast1", // Firestoreのリージョンに合わせる（よく使う）
  },
  async (event) => {
    try {
      const snap = event.data;
      if (!snap) {
        logger.warn("No snapshot in event");
        return;
      }

      const earningId = event.params.earningId;
      const data = snap.data() || {};

      const targetUid = data.uid;
      const amount = Number.isInteger(data.amount) ? data.amount : 0;
      const projectName = data.projectNameSnapshot || "案件";
      const payoutConfirmedAt = data.payoutConfirmedAt;

      if (!targetUid) {
        logger.warn("Missing uid on earnings doc", { earningId });
        return;
      }

      // profiles/{uid} から FCM token を取得（単一端末MVP）
      const profileRef = admin.firestore().collection("profiles").doc(targetUid);
      const profileSnap = await profileRef.get();
      if (!profileSnap.exists) {
        logger.warn("Profile not found", { targetUid, earningId });
        return;
      }

      const profile = profileSnap.data() || {};
      const token = profile.fcmToken;

      if (!token) {
        logger.warn("No fcmToken on profile", { targetUid, earningId });
        return;
      }

      // 日付文字列（yyyy/MM/dd）
      let ymd = "";
      try {
        if (payoutConfirmedAt && payoutConfirmedAt.toDate) {
          const d = payoutConfirmedAt.toDate();
          const mm = String(d.getMonth() + 1).padStart(2, "0");
          const dd = String(d.getDate()).padStart(2, "0");
          ymd = `${d.getFullYear()}/${mm}/${dd}`;
        }
      } catch (e) {
        logger.warn("Failed to format payoutConfirmedAt", e);
      }

      const title = "支払い確定";
      const body =
        `${projectName} の売上 ` +
        `¥${amount.toLocaleString("ja-JP")} が反映されました` +
        (ymd ? `（${ymd}）` : "");

      const message = {
        token,
        notification: { title, body },
        data: {
          type: "earning_confirmed",
          earningId: String(earningId),
          uid: String(targetUid),
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
      logger.info("FCM sent", { res, targetUid, earningId });
    } catch (e) {
      logger.error("onEarningCreated failed", e);
    }
  }
);