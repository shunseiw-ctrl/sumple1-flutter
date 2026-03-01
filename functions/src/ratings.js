const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

/**
 * ratings/{ratingId} 作成時に、profiles/{targetUid} の評価集計を更新
 *
 * ratings ドキュメントの想定フィールド:
 * - targetUid: string (被評価者=職人のUID)
 * - stars: int (1-5)
 * - raterUid: string (評価者=管理者のUID)
 * - applicationId: string
 * - jobId: string
 * - comment: string
 * - createdAt: Timestamp
 */
exports.onRatingCreated = onDocumentCreated(
  {
    document: "ratings/{ratingId}",
    region: "asia-northeast1",
  },
  async (event) => {
    try {
      const snap = event.data;
      if (!snap) {
        logger.warn("No snapshot in event");
        return;
      }

      const ratingId = event.params.ratingId;
      const data = snap.data() || {};

      const targetUid = data.targetUid;
      const stars = Number.isInteger(data.stars) ? data.stars : 0;

      if (!targetUid) {
        logger.warn("Missing targetUid on ratings doc", { ratingId });
        return;
      }

      if (stars < 1 || stars > 5) {
        logger.warn("Invalid stars value", { ratingId, stars });
        return;
      }

      const profileRef = admin.firestore().collection("profiles").doc(targetUid);

      await admin.firestore().runTransaction(async (tx) => {
        const profileSnap = await tx.get(profileRef);

        let ratingCount = 0;
        let ratingTotal = 0;

        if (profileSnap.exists) {
          const profile = profileSnap.data() || {};
          ratingCount = Number.isInteger(profile.ratingCount) ? profile.ratingCount : 0;
          ratingTotal = Number.isInteger(profile.ratingTotal) ? profile.ratingTotal : 0;
        }

        const newCount = ratingCount + 1;
        const newTotal = ratingTotal + stars;
        const newAverage = Math.round((newTotal / newCount) * 10) / 10;

        tx.set(
          profileRef,
          {
            ratingCount: newCount,
            ratingTotal: newTotal,
            ratingAverage: newAverage,
          },
          { merge: true },
        );
      });

      logger.info("Rating aggregation updated", { targetUid, ratingId, stars });
    } catch (e) {
      logger.error("onRatingCreated failed", e);
    }
  },
);
