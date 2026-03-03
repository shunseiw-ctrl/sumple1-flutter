const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

exports.simulateStripeWebhook = onCall(
  {
    region: "asia-northeast1",
    maxInstances: 2,
  },
  async (request) => {
    // 本番環境では無効化
    const isProduction = process.env.GCLOUD_PROJECT === "alba-work-production"
      || process.env.NODE_ENV === "production";

    if (isProduction) {
      throw new Error("simulateStripeWebhook is disabled in production environment");
    }

    const { paymentId, eventType } = request.data || {};

    if (!paymentId) {
      throw new Error("paymentId is required");
    }

    const db = admin.firestore();
    const paymentRef = db.collection("payments").doc(paymentId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      throw new Error(`Payment ${paymentId} not found`);
    }

    const simulatedEvent = eventType || "payment_intent.succeeded";

    if (simulatedEvent === "payment_intent.succeeded") {
      await paymentRef.update({
        status: "succeeded",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        simulatedWebhook: true,
      });

      logger.info("Simulated webhook: payment_intent.succeeded", { paymentId });

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
