const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

/**
 * deleteUserData — 認証済みユーザーの全データを削除する onCall CF
 *
 * 削除対象:
 *   profiles/{uid}, applications, earnings, chats (+ messages), ratings,
 *   favorites/{uid}, notifications, contacts
 * 匿名化: payments (workerUid → "deleted_user")
 * 最後に Firebase Auth アカウントを削除
 */
exports.deleteUserData = onCall(
  { region: "asia-northeast1", maxInstances: 5 },
  async (request) => {
    // 認証チェック
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "認証が必要です");
    }

    const uid = request.auth.uid;
    const db = admin.firestore();
    const BATCH_LIMIT = 400; // Firestore batch limit is 500, leave margin

    /**
     * クエリで取得したドキュメントをバッチ削除
     */
    async function deleteByQuery(collectionName, fieldName, fieldValue) {
      let deleted = 0;
      let query = db
        .collection(collectionName)
        .where(fieldName, "==", fieldValue)
        .limit(BATCH_LIMIT);

      // eslint-disable-next-line no-constant-condition
      while (true) {
        const snapshot = await query.get();
        if (snapshot.empty) break;

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        deleted += snapshot.size;
      }
      return deleted;
    }

    /**
     * chats サブコレクション (messages) を含めて削除
     */
    async function deleteChatsWithMessages(fieldValue) {
      let deleted = 0;
      let query = db
        .collection("chats")
        .where("applicantUid", "==", fieldValue)
        .limit(BATCH_LIMIT);

      // eslint-disable-next-line no-constant-condition
      while (true) {
        const snapshot = await query.get();
        if (snapshot.empty) break;

        for (const chatDoc of snapshot.docs) {
          // サブコレクション messages を先に削除
          const messagesSnap = await chatDoc.ref
            .collection("messages")
            .limit(BATCH_LIMIT)
            .get();

          if (!messagesSnap.empty) {
            const msgBatch = db.batch();
            messagesSnap.docs.forEach((msgDoc) => {
              msgBatch.delete(msgDoc.ref);
            });
            await msgBatch.commit();
            deleted += messagesSnap.size;
          }

          // chat ドキュメント自体を削除
          await chatDoc.ref.delete();
          deleted += 1;
        }
      }
      return deleted;
    }

    /**
     * payments を匿名化（workerUid を "deleted_user" に変更）
     */
    async function anonymizePayments(fieldValue) {
      let anonymized = 0;
      let query = db
        .collection("payments")
        .where("workerUid", "==", fieldValue)
        .limit(BATCH_LIMIT);

      // eslint-disable-next-line no-constant-condition
      while (true) {
        const snapshot = await query.get();
        if (snapshot.empty) break;

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
          batch.update(doc.ref, { workerUid: "deleted_user" });
        });
        await batch.commit();
        anonymized += snapshot.size;
      }
      return anonymized;
    }

    try {
      logger.info("Account deletion started", { uid });

      // 1. profiles/{uid} 削除
      const profileRef = db.collection("profiles").doc(uid);
      const profileSnap = await profileRef.get();
      if (profileSnap.exists) {
        await profileRef.delete();
      }

      // 2. applications (applicantUid == uid)
      await deleteByQuery("applications", "applicantUid", uid);

      // 3. earnings (uid == uid)
      await deleteByQuery("earnings", "uid", uid);

      // 4. chats (applicantUid == uid) + サブコレクション messages
      await deleteChatsWithMessages(uid);

      // 5. ratings (targetUid == uid)
      await deleteByQuery("ratings", "targetUid", uid);

      // 6. favorites/{uid}
      const favRef = db.collection("favorites").doc(uid);
      const favSnap = await favRef.get();
      if (favSnap.exists) {
        await favRef.delete();
      }

      // 7. notifications (targetUid == uid)
      await deleteByQuery("notifications", "targetUid", uid);

      // 8. contacts (uid == uid)
      await deleteByQuery("contacts", "uid", uid);

      // 9. payments — 匿名化（監査証跡保持）
      await anonymizePayments(uid);

      // 10. Firebase Auth アカウント削除
      await admin.auth().deleteUser(uid);

      // 11. 監査ログ記録
      await db.collection("audit_logs").add({
        action: "account_deleted",
        actorUid: uid,
        targetCollection: "profiles",
        targetDocId: uid,
        details: { reason: "user_requested" },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info("Account deletion completed", { uid });
      return { success: true };
    } catch (error) {
      logger.error("Account deletion failed", { uid, error: error.message });
      throw new HttpsError("internal", "アカウント削除に失敗しました");
    }
  },
);
