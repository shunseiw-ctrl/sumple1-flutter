const admin = require("firebase-admin");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const REGION = "asia-northeast1";

/**
 * 既存データから stats/realtime の初期カウントを計算するワンショット callable
 * 管理者のみ実行可能
 */
exports.initializeCounters = onCall(
  { region: REGION },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "ログインが必要です");
    }

    // 管理者チェック
    const uid = request.auth.uid;
    const adminDoc = await admin
      .firestore()
      .doc("config/admins")
      .get();

    if (!adminDoc.exists) {
      throw new HttpsError("permission-denied", "管理者設定が見つかりません");
    }

    const adminData = adminDoc.data() || {};
    const adminUids = adminData.adminUids || [];
    const adminEmails = (adminData.emails || []).map((e) =>
      e.toLowerCase().trim(),
    );

    const email = (request.auth.token.email || "").toLowerCase().trim();
    const isAdmin = adminUids.includes(uid) || adminEmails.includes(email);

    if (!isAdmin) {
      throw new HttpsError("permission-denied", "管理者権限が必要です");
    }

    const db = admin.firestore();

    const [jobsSnap, appsSnap, profilesSnap, pendingSnap] = await Promise.all([
      db.collection("jobs").count().get(),
      db.collection("applications").count().get(),
      db.collection("profiles").count().get(),
      db
        .collection("applications")
        .where("status", "==", "applied")
        .count()
        .get(),
    ]);

    const stats = {
      totalJobs: jobsSnap.data().count,
      totalApplications: appsSnap.data().count,
      totalUsers: profilesSnap.data().count,
      pendingApplications: pendingSnap.data().count,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.doc("stats/realtime").set(stats);

    logger.info("Counters initialized", stats);

    return {
      success: true,
      ...stats,
      updatedAt: new Date().toISOString(),
    };
  },
);
