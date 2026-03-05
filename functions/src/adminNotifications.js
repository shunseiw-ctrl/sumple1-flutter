const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

const REGION = "asia-northeast1";

/**
 * 管理者UIDリストを取得
 */
async function getAdminUids() {
  const doc = await admin.firestore().doc("config/admins").get();
  if (!doc.exists) return [];
  return doc.data().adminUids || [];
}

/**
 * 管理者全員に通知ドキュメントを作成
 */
async function notifyAdmins(title, body, type, data = {}) {
  const adminUids = await getAdminUids();
  const batch = admin.firestore().batch();
  for (const uid of adminUids) {
    const ref = admin.firestore().collection("notifications").doc();
    batch.set(ref, {
      targetUid: uid,
      title,
      body,
      type,
      data,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  logger.info(`Notified ${adminUids.length} admins`, { type });
}

/**
 * #1: 新規応募 → 管理者に通知
 */
exports.onApplicationCreatedNotify = onDocumentCreated(
  { document: "applications/{appId}", region: REGION },
  async (event) => {
    try {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data() || {};
      const jobTitle = data.jobTitleSnapshot || data.projectNameSnapshot || "案件";
      const workerName = data.workerNameSnapshot || "ワーカー";
      await notifyAdmins(
        "新規応募",
        `${workerName}が「${jobTitle}」に応募しました`,
        "new_application",
        { applicationId: event.params.appId, jobId: data.jobId || "" },
      );
    } catch (e) {
      logger.error("onApplicationCreatedNotify failed", e);
    }
  },
);

/**
 * #2: 日報提出 → 管理者に通知
 */
exports.onWorkReportCreatedNotify = onDocumentCreated(
  { document: "applications/{appId}/work_reports/{reportId}", region: REGION },
  async (event) => {
    try {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data() || {};
      const reportDate = data.reportDate || "";
      await notifyAdmins(
        "日報提出",
        `${reportDate}の日報が提出されました`,
        "work_report",
        { applicationId: event.params.appId, reportId: event.params.reportId },
      );
    } catch (e) {
      logger.error("onWorkReportCreatedNotify failed", e);
    }
  },
);

/**
 * #3: 検査失敗 → 管理者+ワーカーに通知
 */
exports.onInspectionCreatedNotify = onDocumentCreated(
  { document: "applications/{appId}/inspections/{inspectionId}", region: REGION },
  async (event) => {
    try {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data() || {};
      const result = data.result || "unknown";

      if (result === "failed" || result === "partial") {
        // 管理者に通知
        await notifyAdmins(
          "検査不合格",
          `検査結果: ${result === "failed" ? "不合格" : "一部不合格"}`,
          "inspection_failed",
          { applicationId: event.params.appId, inspectionId: event.params.inspectionId },
        );

        // ワーカーにも通知
        const appDoc = await admin.firestore().doc(`applications/${event.params.appId}`).get();
        if (appDoc.exists) {
          const appData = appDoc.data() || {};
          const workerUid = appData.applicantUid;
          if (workerUid) {
            await admin.firestore().collection("notifications").add({
              targetUid: workerUid,
              title: "検査結果",
              body: result === "failed" ? "検査が不合格でした。修正をお願いします。" : "検査で一部不合格の項目があります。",
              type: "inspection_result",
              data: { applicationId: event.params.appId },
              read: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      logger.error("onInspectionCreatedNotify failed", e);
    }
  },
);

/**
 * #4: 毎朝9時JST 日次サマリー通知
 */
exports.sendDailySummary = onSchedule(
  { schedule: "0 9 * * *", region: REGION, timeZone: "Asia/Tokyo" },
  async () => {
    try {
      // 未処理件数を集計
      const [pendingApps, pendingQuals, pendingReports] = await Promise.all([
        admin.firestore().collection("applications")
          .where("status", "==", "applied").count().get(),
        admin.firestore().collectionGroup("qualifications_v2")
          .where("verificationStatus", "==", "pending").count().get(),
        admin.firestore().collectionGroup("work_reports")
          .where("reviewStatus", "==", "pending").count().get(),
      ]);

      const apps = pendingApps.data().count;
      const quals = pendingQuals.data().count;
      const reports = pendingReports.data().count;
      const total = apps + quals + reports;

      if (total === 0) {
        logger.info("No pending items for daily summary");
        return;
      }

      const parts = [];
      if (apps > 0) parts.push(`未処理応募: ${apps}件`);
      if (quals > 0) parts.push(`資格承認待ち: ${quals}件`);
      if (reports > 0) parts.push(`未レビュー日報: ${reports}件`);

      await notifyAdmins(
        "日次サマリー",
        parts.join("、"),
        "daily_summary",
        { pendingApps: apps, pendingQuals: quals, pendingReports: reports },
      );
    } catch (e) {
      logger.error("sendDailySummary failed", e);
    }
  },
);

/**
 * #5: 6時間ごと 未読リマインド
 */
exports.sendChatUnreadReminder = onSchedule(
  { schedule: "0 */6 * * *", region: REGION, timeZone: "Asia/Tokyo" },
  async () => {
    try {
      const adminUids = await getAdminUids();

      for (const uid of adminUids) {
        const unreadSnap = await admin.firestore().collection("notifications")
          .where("targetUid", "==", uid)
          .where("read", "==", false)
          .count()
          .get();

        const unreadCount = unreadSnap.data().count;
        if (unreadCount >= 5) {
          // FCMプッシュ通知（通知ドキュメントは作らない）
          const profileSnap = await admin.firestore().doc(`profiles/${uid}`).get();
          const token = profileSnap.exists ? (profileSnap.data() || {}).fcmToken : null;
          if (token) {
            await admin.messaging().send({
              token,
              notification: {
                title: "未読通知リマインド",
                body: `未読の通知が${unreadCount}件あります`,
              },
              data: { type: "unread_reminder" },
            });
            logger.info("Sent unread reminder", { uid, unreadCount });
          }
        }
      }
    } catch (e) {
      logger.error("sendChatUnreadReminder failed", e);
    }
  },
);
