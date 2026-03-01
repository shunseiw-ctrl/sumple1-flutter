const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

/**
 * exportUserData — 認証済みユーザーの全データを JSON で返却する onCall CF
 *
 * 取得対象: profiles, applications, earnings, chats (messages 含む),
 *           ratings, favorites, notifications, contacts, payments
 * 機密フィールド除外: fcmToken, stripeAccountId
 */
exports.exportUserData = onCall(
  { region: "asia-northeast1", maxInstances: 5 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "認証が必要です");
    }

    const uid = request.auth.uid;
    const db = admin.firestore();

    // 機密フィールドを除外するヘルパー
    const SENSITIVE_FIELDS = ["fcmToken", "stripeAccountId"];

    function sanitize(data) {
      if (!data) return null;
      const cleaned = { ...data };
      for (const field of SENSITIVE_FIELDS) {
        delete cleaned[field];
      }
      return cleaned;
    }

    /**
     * クエリでコレクションを取得
     */
    async function queryCollection(collectionName, fieldName, fieldValue) {
      const snapshot = await db
        .collection(collectionName)
        .where(fieldName, "==", fieldValue)
        .get();

      return snapshot.docs.map((doc) => ({
        id: doc.id,
        ...sanitize(doc.data()),
      }));
    }

    try {
      logger.info("Data export started", { uid });

      // 1. Profile
      const profileSnap = await db.collection("profiles").doc(uid).get();
      const profile = profileSnap.exists ? sanitize(profileSnap.data()) : null;

      // 2. Applications
      const applications = await queryCollection(
        "applications",
        "applicantUid",
        uid,
      );

      // 3. Earnings
      const earnings = await queryCollection("earnings", "uid", uid);

      // 4. Chats + Messages
      const chatsSnap = await db
        .collection("chats")
        .where("applicantUid", "==", uid)
        .get();

      const chats = [];
      for (const chatDoc of chatsSnap.docs) {
        const messagesSnap = await chatDoc.ref.collection("messages").get();
        const messages = messagesSnap.docs.map((msgDoc) => ({
          id: msgDoc.id,
          ...msgDoc.data(),
        }));
        chats.push({
          id: chatDoc.id,
          ...sanitize(chatDoc.data()),
          messages,
        });
      }

      // 5. Ratings
      const ratings = await queryCollection("ratings", "targetUid", uid);

      // 6. Favorites
      const favSnap = await db.collection("favorites").doc(uid).get();
      const favorites = favSnap.exists ? favSnap.data() : null;

      // 7. Notifications
      const notifications = await queryCollection(
        "notifications",
        "targetUid",
        uid,
      );

      // 8. Contacts
      const contacts = await queryCollection("contacts", "uid", uid);

      // 9. Payments
      const payments = await queryCollection("payments", "workerUid", uid);

      const exportData = {
        exportedAt: new Date().toISOString(),
        uid,
        profile,
        applications,
        earnings,
        chats,
        ratings,
        favorites,
        notifications,
        contacts,
        payments,
      };

      // 監査ログ記録
      await db.collection("audit_logs").add({
        action: "data_exported",
        actorUid: uid,
        targetCollection: "profiles",
        targetDocId: uid,
        details: {},
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info("Data export completed", { uid });
      return exportData;
    } catch (error) {
      logger.error("Data export failed", { uid, error: error.message });
      throw new HttpsError("internal", "データエクスポートに失敗しました");
    }
  },
);
