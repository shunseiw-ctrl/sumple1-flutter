const admin = require("firebase-admin");

const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

admin.initializeApp();

// コスト制御
setGlobalOptions({ maxInstances: 10 });

// --- LINE認証 Cloud Functions ---
const lineAuth = require("./src/lineAuth");
exports.lineRedirect = lineAuth.lineRedirect;
exports.lineCallback = lineAuth.lineCallback;
exports.lineTokenExchange = lineAuth.lineTokenExchange;

// --- KPI集計バッチ（日次: 毎日 0:00 JST = 15:00 UTC）---
exports.dailyStatsAggregation = onSchedule(
  {
    schedule: "0 15 * * *",
    region: "asia-northeast1",
    timeZone: "Asia/Tokyo",
  },
  async (event) => {
    try {
      const now = new Date();
      const jst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
      const dateKey = jst.toISOString().split("T")[0];

      const db = admin.firestore();

      const [jobsSnap, appsSnap, profilesSnap] = await Promise.all([
        db.collection("jobs").count().get(),
        db.collection("applications").count().get(),
        db.collection("profiles").count().get(),
      ]);

      await db.doc("stats/daily").collection("entries").doc(dateKey).set(
        {
          totalJobs: jobsSnap.data().count,
          totalApplications: appsSnap.data().count,
          totalUsers: profilesSnap.data().count,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      await db.doc("stats/realtime").set(
        {
          totalJobs: jobsSnap.data().count,
          totalApplications: appsSnap.data().count,
          totalUsers: profilesSnap.data().count,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      logger.info("Daily stats aggregated", { dateKey });
    } catch (e) {
      logger.error("Daily stats aggregation failed", e);
    }
  }
);

// --- earnings/{earningId} 作成時にFCM通知 ---
exports.onEarningCreated = onDocumentCreated(
  {
    document: "earnings/{earningId}",
    region: "asia-northeast1",
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
          notification: { channelId: "default" },
        },
        apns: {
          headers: { "apns-priority": "10" },
        },
      };

      const res = await admin.messaging().send(message);
      logger.info("FCM sent", { res, targetUid, earningId });
    } catch (e) {
      logger.error("onEarningCreated failed", e);
    }
  }
);
