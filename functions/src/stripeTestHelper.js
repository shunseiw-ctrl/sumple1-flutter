const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

exports.simulateStripeWebhook = onCall(
  {
    region: "asia-northeast1",
    maxInstances: 2,
  },
  async (request) => {
    // 認証チェック
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "認証が必要です");
    }

    // 管理者ロール検証
    const uid = request.auth.uid;
    const profileDoc = await admin.firestore().collection("profiles").doc(uid).get();
    if (!profileDoc.exists || profileDoc.data().role !== "admin") {
      throw new HttpsError("permission-denied", "管理者権限が必要です");
    }

    // 本番環境では無効化
    const isProduction = process.env.GCLOUD_PROJECT === "alba-work-production"
      || process.env.NODE_ENV === "production";

    if (isProduction) {
      throw new HttpsError("failed-precondition", "simulateStripeWebhook is disabled in production environment");
    }

    const { paymentId, eventType } = request.data || {};

    if (!paymentId) {
      throw new HttpsError("invalid-argument", "paymentId is required");
    }

    const db = admin.firestore();
    const paymentRef = db.collection("payments").doc(paymentId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      throw new HttpsError("not-found", `Payment ${paymentId} not found`);
    }

    const simulatedEvent = eventType || "payment_intent.succeeded";

    if (simulatedEvent === "payment_intent.succeeded") {
      await paymentRef.update({
        status: "succeeded",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        simulatedWebhook: true,
      });

      logger.info("Simulated webhook: payment_intent.succeeded", { paymentId, uid });

      return {
        success: true,
        event: simulatedEvent,
        paymentId,
        message: "Payment status updated to succeeded (test mode)",
      };
    }

    return {
      success: false,
      message: `Unsupported event type: ${simulatedEvent}`,
    };
  }
);
