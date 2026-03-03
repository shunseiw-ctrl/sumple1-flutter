const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

exports.onVerificationStatusChanged = onDocumentUpdated(
  {
    document: "identity_verification/{uid}",
    region: "asia-northeast1",
  },
  async (event) => {
    try {
      const before = event.data.before.data();
      const after = event.data.after.data();
      const uid = event.params.uid;

      if (!before || !after) return;

      // ステータスが変わっていない場合はスキップ
      if (before.status === after.status) return;

      const db = admin.firestore();

      if (after.status === "pending") {
        // ユーザーが申請/再申請 → 管理者に通知
        const adminsDoc = await db.doc("config/admins").get();
        const adminUids = adminsDoc.exists
          ? adminsDoc.data().adminUids || []
          : [];

        const batch = db.batch();
        for (const adminUid of adminUids) {
          const notifRef = db.collection("notifications").doc();
          batch.set(notifRef, {
            targetUid: adminUid,
            title: "本人確認申請",
            body: "新しい本人確認申請があります。確認してください。",
            type: "identity_verification_pending",
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        logger.info("Admin notified of pending verification", { uid });
      } else if (
        after.status === "approved" ||
        after.status === "rejected"
      ) {
        // 管理者が承認/却下 → ユーザーに通知
        const isApproved = after.status === "approved";
        const title = isApproved ? "本人確認完了" : "本人確認結果";
        const body = isApproved
          ? "本人確認が承認されました。"
          : `本人確認が却下されました。${after.rejectionReason ? "理由: " + after.rejectionReason : "再度お試しください。"}`;

        await db.collection("notifications").add({
          targetUid: uid,
          title,
          body,
          type: isApproved
            ? "identity_verification_approved"
            : "identity_verification_rejected",
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info("User notified of verification result", {
          uid,
          status: after.status,
        });
      }
    } catch (e) {
      logger.error("onVerificationStatusChanged failed", e);
    }
  }
);
