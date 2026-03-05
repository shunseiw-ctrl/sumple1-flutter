const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

/**
 * mergeAccounts — 2つのFirebase Authアカウントのデータを統合する onCall CF
 *
 * credential-already-in-use エラー発生時に呼び出される。
 * conflictingEmail で旧アカウントを特定し、データを現在のアカウントにマージ後、旧アカウントを削除。
 */
exports.mergeAccounts = onCall(
  { region: "asia-northeast1", maxInstances: 5 },
  async (request) => {
    // 認証チェック
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "認証が必要です");
    }

    const primaryUid = request.auth.uid;
    const { conflictingEmail } = request.data || {};

    // 入力バリデーション
    if (!conflictingEmail || typeof conflictingEmail !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "conflictingEmail は必須です",
      );
    }

    // レート制限（1 req/hour）
    const { enforceRateLimit, PRESETS } = require("./rateLimiter");
    await enforceRateLimit(
      `merge:${primaryUid}`,
      PRESETS.merge.maxRequests,
      PRESETS.merge.windowMs,
    );

    const db = admin.firestore();
    const BATCH_LIMIT = 400;

    // 旧ユーザー取得
    let deprecatedUser;
    try {
      deprecatedUser = await admin.auth().getUserByEmail(conflictingEmail);
    } catch (error) {
      throw new HttpsError(
        "not-found",
        "指定されたメールアドレスのアカウントが見つかりません",
      );
    }

    const deprecatedUid = deprecatedUser.uid;

    // 安全チェック: 同一UID拒否
    if (primaryUid === deprecatedUid) {
      throw new HttpsError(
        "invalid-argument",
        "同一アカウントは統合できません",
      );
    }

    // 安全チェック: 管理者アカウント拒否
    const adminDoc = await db.collection("config").doc("admins").get();
    if (adminDoc.exists) {
      const adminUids = adminDoc.data().uids || [];
      if (adminUids.includes(deprecatedUid) || adminUids.includes(primaryUid)) {
        throw new HttpsError(
          "permission-denied",
          "管理者アカウントは統合できません",
        );
      }
    }

    /**
     * クエリで取得したドキュメントのフィールドをバッチ更新
     */
    async function updateByQuery(collection, field, oldUid, newUid) {
      let updated = 0;
      let query = db
        .collection(collection)
        .where(field, "==", oldUid)
        .limit(BATCH_LIMIT);

      // eslint-disable-next-line no-constant-condition
      while (true) {
        const snapshot = await query.get();
        if (snapshot.empty) break;

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
          batch.update(doc.ref, { [field]: newUid });
        });
        await batch.commit();
        updated += snapshot.size;
      }
      return updated;
    }

    /**
     * プロフィールマージ — primaryが空のフィールドをdeprecatedから補完
     * qualifications_v2 サブコレクションもコピー
     */
    async function mergeProfiles(pUid, dUid) {
      const primaryRef = db.collection("profiles").doc(pUid);
      const deprecatedRef = db.collection("profiles").doc(dUid);

      const [primarySnap, deprecatedSnap] = await Promise.all([
        primaryRef.get(),
        deprecatedRef.get(),
      ]);

      if (!deprecatedSnap.exists) return;

      // プロフィールフィールド補完
      if (primarySnap.exists) {
        const primaryData = primarySnap.data();
        const deprecatedData = deprecatedSnap.data();
        const updates = {};

        for (const [key, value] of Object.entries(deprecatedData)) {
          if (
            key !== "uid" &&
            key !== "createdAt" &&
            key !== "linkedProviders" &&
            (primaryData[key] === undefined ||
              primaryData[key] === null ||
              primaryData[key] === "")
          ) {
            updates[key] = value;
          }
        }

        if (Object.keys(updates).length > 0) {
          updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
          await primaryRef.update(updates);
        }
      } else {
        // primary プロフィールがない場合、deprecatedをコピー
        const data = deprecatedSnap.data();
        data.uid = pUid;
        data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
        await primaryRef.set(data);
      }

      // qualifications_v2 サブコレクションコピー
      const qualSnap = await deprecatedRef
        .collection("qualifications_v2")
        .get();

      if (!qualSnap.empty) {
        const batch = db.batch();
        for (const doc of qualSnap.docs) {
          const destRef = primaryRef
            .collection("qualifications_v2")
            .doc(doc.id);
          const destSnap = await destRef.get();
          if (!destSnap.exists) {
            batch.set(destRef, doc.data());
          }
        }
        await batch.commit();

        // deprecated の qualifications_v2 を削除
        const delBatch = db.batch();
        qualSnap.docs.forEach((doc) => delBatch.delete(doc.ref));
        await delBatch.commit();
      }

      // deprecated プロフィール削除
      await deprecatedRef.delete();
    }

    /**
     * チャットマージ — applicantUid更新 + messages の senderUid 更新
     */
    async function mergeChats(pUid, dUid) {
      let query = db
        .collection("chats")
        .where("applicantUid", "==", dUid)
        .limit(BATCH_LIMIT);

      // eslint-disable-next-line no-constant-condition
      while (true) {
        const snapshot = await query.get();
        if (snapshot.empty) break;

        for (const chatDoc of snapshot.docs) {
          // messages サブコレクションの senderUid 更新
          let msgQuery = chatDoc.ref
            .collection("messages")
            .where("senderUid", "==", dUid)
            .limit(BATCH_LIMIT);

          // eslint-disable-next-line no-constant-condition
          while (true) {
            const msgSnap = await msgQuery.get();
            if (msgSnap.empty) break;

            const msgBatch = db.batch();
            msgSnap.docs.forEach((msgDoc) => {
              msgBatch.update(msgDoc.ref, { senderUid: pUid });
            });
            await msgBatch.commit();
          }

          // chat ドキュメントの applicantUid 更新
          await chatDoc.ref.update({ applicantUid: pUid });
        }
      }
    }

    /**
     * お気に入りマージ — Mapを統合
     */
    async function mergeFavorites(pUid, dUid) {
      const primaryRef = db.collection("favorites").doc(pUid);
      const deprecatedRef = db.collection("favorites").doc(dUid);

      const [primarySnap, deprecatedSnap] = await Promise.all([
        primaryRef.get(),
        deprecatedRef.get(),
      ]);

      if (!deprecatedSnap.exists) return;

      if (primarySnap.exists) {
        const primaryData = primarySnap.data();
        const deprecatedData = deprecatedSnap.data();
        const merged = { ...deprecatedData, ...primaryData };
        merged.updatedAt = admin.firestore.FieldValue.serverTimestamp();
        await primaryRef.set(merged);
      } else {
        const data = deprecatedSnap.data();
        data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
        await primaryRef.set(data);
      }

      await deprecatedRef.delete();
    }

    /**
     * 本人確認マージ — primaryが未検証ならdeprecatedから移動
     */
    async function mergeIdentityVerification(pUid, dUid) {
      const primaryRef = db.collection("identity_verification").doc(pUid);
      const deprecatedRef = db.collection("identity_verification").doc(dUid);

      const [primarySnap, deprecatedSnap] = await Promise.all([
        primaryRef.get(),
        deprecatedRef.get(),
      ]);

      if (!deprecatedSnap.exists) return;

      if (!primarySnap.exists || primarySnap.data().status !== "approved") {
        const data = deprecatedSnap.data();
        data.uid = pUid;
        data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
        await primaryRef.set(data);
      }

      await deprecatedRef.delete();
    }

    /**
     * 紹介コードマージ — primaryになければdeprecatedから移動
     */
    async function mergeReferralCodes(pUid, dUid) {
      const primaryRef = db.collection("referral_codes").doc(pUid);
      const deprecatedRef = db.collection("referral_codes").doc(dUid);

      const [primarySnap, deprecatedSnap] = await Promise.all([
        primaryRef.get(),
        deprecatedRef.get(),
      ]);

      if (!deprecatedSnap.exists) return;

      if (!primarySnap.exists) {
        const data = deprecatedSnap.data();
        data.uid = pUid;
        await primaryRef.set(data);
      }

      await deprecatedRef.delete();
    }

    /**
     * 管理者メモマージ — テキスト追記結合
     */
    async function mergeAdminMemos(pUid, dUid) {
      const primaryRef = db.collection("admin_memos").doc(pUid);
      const deprecatedRef = db.collection("admin_memos").doc(dUid);

      const [primarySnap, deprecatedSnap] = await Promise.all([
        primaryRef.get(),
        deprecatedRef.get(),
      ]);

      if (!deprecatedSnap.exists) return;

      const deprecatedMemo = deprecatedSnap.data().memo || "";

      if (primarySnap.exists) {
        const primaryMemo = primarySnap.data().memo || "";
        const merged = primaryMemo
          ? `${primaryMemo}\n--- 統合アカウントより ---\n${deprecatedMemo}`
          : deprecatedMemo;
        await primaryRef.update({
          memo: merged,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        await primaryRef.set({
          memo: deprecatedMemo,
          uid: pUid,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await deprecatedRef.delete();
    }

    /**
     * 応募マージ — 同一jobIdの重複は古い方を削除
     */
    async function mergeApplications(pUid, dUid) {
      // primary の既存応募 jobId を収集
      const primaryApps = await db
        .collection("applications")
        .where("applicantUid", "==", pUid)
        .get();

      const primaryJobIds = new Set(
        primaryApps.docs.map((doc) => doc.data().jobId),
      );

      // deprecated の応募を処理
      let query = db
        .collection("applications")
        .where("applicantUid", "==", dUid)
        .limit(BATCH_LIMIT);

      // eslint-disable-next-line no-constant-condition
      while (true) {
        const snapshot = await query.get();
        if (snapshot.empty) break;

        const batch = db.batch();
        for (const doc of snapshot.docs) {
          const jobId = doc.data().jobId;
          if (primaryJobIds.has(jobId)) {
            // 重複: 古い方（deprecated）を削除
            batch.delete(doc.ref);
          } else {
            // UID更新
            batch.update(doc.ref, { applicantUid: pUid });
            primaryJobIds.add(jobId);
          }
        }
        await batch.commit();
      }
    }

    /**
     * LINE連携アカウント更新
     */
    async function mergeLineLinkedAccounts(pUid, dUid) {
      const snapshot = await db
        .collection("line_linked_accounts")
        .where("firebaseUid", "==", dUid)
        .get();

      if (!snapshot.empty) {
        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
          batch.update(doc.ref, { firebaseUid: pUid });
        });
        await batch.commit();
      }
    }

    try {
      logger.info("Account merge started", {
        primaryUid,
        deprecatedUid,
        conflictingEmail,
      });

      // 1. プロフィールマージ
      await mergeProfiles(primaryUid, deprecatedUid);

      // 2. お気に入りマージ
      await mergeFavorites(primaryUid, deprecatedUid);

      // 3. 本人確認マージ
      await mergeIdentityVerification(primaryUid, deprecatedUid);

      // 4. 紹介コードマージ
      await mergeReferralCodes(primaryUid, deprecatedUid);

      // 5. 管理者メモマージ
      await mergeAdminMemos(primaryUid, deprecatedUid);

      // 6. 応募マージ（重複チェック付き）
      await mergeApplications(primaryUid, deprecatedUid);

      // 7. チャットマージ
      await mergeChats(primaryUid, deprecatedUid);

      // 8. コレクション別 UID 更新
      await updateByQuery("earnings", "uid", deprecatedUid, primaryUid);
      await updateByQuery(
        "monthly_statements",
        "workerUid",
        deprecatedUid,
        primaryUid,
      );
      await updateByQuery(
        "early_payment_requests",
        "workerUid",
        deprecatedUid,
        primaryUid,
      );
      await updateByQuery("payments", "workerUid", deprecatedUid, primaryUid);
      await updateByQuery(
        "notifications",
        "targetUid",
        deprecatedUid,
        primaryUid,
      );
      await updateByQuery("contacts", "uid", deprecatedUid, primaryUid);

      // 9. ratings — targetUid と raterUid の両方を更新
      await updateByQuery("ratings", "targetUid", deprecatedUid, primaryUid);
      await updateByQuery("ratings", "raterUid", deprecatedUid, primaryUid);

      // 10. referrals — referrerUid と refereeUid の両方を更新
      await updateByQuery(
        "referrals",
        "referrerUid",
        deprecatedUid,
        primaryUid,
      );
      await updateByQuery(
        "referrals",
        "refereeUid",
        deprecatedUid,
        primaryUid,
      );

      // 11. LINE連携アカウント更新
      await mergeLineLinkedAccounts(primaryUid, deprecatedUid);

      // 12. 旧 Firebase Auth ユーザー削除
      await admin.auth().deleteUser(deprecatedUid);

      // 13. 監査ログ記録
      await db.collection("audit_logs").add({
        action: "accounts_merged",
        actorUid: primaryUid,
        targetCollection: "profiles",
        targetDocId: deprecatedUid,
        details: {
          primaryUid,
          deprecatedUid,
          conflictingEmail,
        },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info("Account merge completed", { primaryUid, deprecatedUid });
      return { success: true };
    } catch (error) {
      logger.error("Account merge failed", {
        primaryUid,
        deprecatedUid,
        error: error.message,
      });

      // HttpsError はそのまま再スロー
      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", "アカウント統合に失敗しました");
    }
  },
);
