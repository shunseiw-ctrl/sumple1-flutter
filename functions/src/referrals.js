const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

/**
 * referrals/{referralId} 作成時に:
 * 1. コードの存在確認
 * 2. 自己紹介防止
 * 3. rewardGranted を true に設定
 * 4. 両者の profiles に referralBonus フラグ付与
 * 5. referral_codes の usageCount をインクリメント
 */
exports.onReferralApplied = onDocumentCreated(
  { document: "referrals/{referralId}", region: "asia-northeast1" },
  async (event) => {
    try {
      const snap = event.data;
      if (!snap) {
        logger.warn("No snapshot in event");
        return;
      }

      const referralId = event.params.referralId;
      const data = snap.data() || {};

      const code = data.code;
      const referrerUid = data.referrerUid;
      const refereeUid = data.refereeUid;

      if (!code || !referrerUid || !refereeUid) {
        logger.warn("Missing required fields on referral doc", { referralId });
        return;
      }

      // 自己紹介防止
      if (referrerUid === refereeUid) {
        logger.warn("Self-referral detected", { referralId, referrerUid });
        return;
      }

      const db = admin.firestore();

      // コードの存在確認
      const codeDoc = await db.collection("referral_codes").doc(referrerUid).get();
      if (!codeDoc.exists) {
        logger.warn("Referral code doc not found for referrer", {
          referralId,
          referrerUid,
        });
        return;
      }

      const codeData = codeDoc.data() || {};
      if (codeData.code !== code) {
        logger.warn("Code mismatch", {
          referralId,
          expected: codeData.code,
          actual: code,
        });
        return;
      }

      const batch = db.batch();

      // 紹介ドキュメントを completed + rewardGranted に更新
      batch.update(snap.ref, {
        status: "completed",
        rewardGranted: true,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 紹介者と被紹介者の profiles に referralBonus フラグを付与
      const referrerProfileRef = db.collection("profiles").doc(referrerUid);
      batch.set(
        referrerProfileRef,
        { referralBonus: true, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true }
      );

      const refereeProfileRef = db.collection("profiles").doc(refereeUid);
      batch.set(
        refereeProfileRef,
        { referralBonus: true, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true }
      );

      // usageCount をインクリメント
      const codeRef = db.collection("referral_codes").doc(referrerUid);
      batch.update(codeRef, {
        usageCount: admin.firestore.FieldValue.increment(1),
      });

      await batch.commit();
      logger.info("Referral processed successfully", {
        referralId,
        referrerUid,
        refereeUid,
        code,
      });
    } catch (e) {
      logger.error("onReferralApplied failed", e);
    }
  }
);
