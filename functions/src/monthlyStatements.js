const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

const REGION = "asia-northeast1";

/**
 * earnings/{earningId} 作成時に月次明細を自動生成/更新
 */
exports.onEarningCreated = onDocumentCreated(
  {
    document: "earnings/{earningId}",
    region: REGION,
  },
  async (event) => {
    try {
      const snap = event.data;
      if (!snap) {
        logger.warn("No snapshot in event");
        return;
      }

      const data = snap.data() || {};
      const workerUid = data.uid;
      const amount = Number.isInteger(data.amount) ? data.amount : 0;
      const applicationId = data.applicationId || "";
      const projectName = data.projectNameSnapshot || "案件";

      if (!workerUid) {
        logger.warn("Missing uid on earnings doc");
        return;
      }

      // payoutConfirmedAt から YYYY-MM を算出
      let month = "";
      let completedDate = "";
      const payoutConfirmedAt = data.payoutConfirmedAt;
      if (payoutConfirmedAt && payoutConfirmedAt.toDate) {
        const d = payoutConfirmedAt.toDate();
        const mm = String(d.getMonth() + 1).padStart(2, "0");
        month = `${d.getFullYear()}-${mm}`;
        completedDate = `${d.getFullYear()}-${mm}-${String(d.getDate()).padStart(2, "0")}`;
      } else {
        // フォールバック: 現在日時
        const now = new Date();
        const mm = String(now.getMonth() + 1).padStart(2, "0");
        month = `${now.getFullYear()}-${mm}`;
        completedDate = `${now.getFullYear()}-${mm}-${String(now.getDate()).padStart(2, "0")}`;
      }

      // 翌月10日を支払日として計算
      const [yearStr, monthStr] = month.split("-");
      const year = parseInt(yearStr, 10);
      const mon = parseInt(monthStr, 10);
      const nextMonth = mon === 12 ? 1 : mon + 1;
      const nextYear = mon === 12 ? year + 1 : year;
      const paymentDate = `${nextYear}-${String(nextMonth).padStart(2, "0")}-10`;

      const db = admin.firestore();

      // workerUid + month が一致する明細を検索
      const existingSnap = await db
        .collection("monthly_statements")
        .where("workerUid", "==", workerUid)
        .where("month", "==", month)
        .limit(1)
        .get();

      const newItem = {
        applicationId,
        jobTitle: projectName,
        completedDate,
        amount,
      };

      if (existingSnap.empty) {
        // 新規作成
        await db.collection("monthly_statements").add({
          workerUid,
          month,
          items: [newItem],
          totalAmount: amount,
          netAmount: amount,
          status: "draft",
          paymentDate,
          earlyPaymentRequested: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info("Monthly statement created", { workerUid, month, amount });
      } else {
        // 既存明細にline item追加
        const docRef = existingSnap.docs[0].ref;
        const existing = existingSnap.docs[0].data();
        const items = existing.items || [];
        items.push(newItem);
        const totalAmount = items.reduce((acc, item) => acc + (item.amount || 0), 0);

        await docRef.update({
          items,
          totalAmount,
          netAmount: totalAmount,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info("Monthly statement updated", { workerUid, month, totalAmount });
      }
    } catch (e) {
      logger.error("onEarningCreated (monthlyStatements) failed", e);
    }
  },
);

/**
 * 毎月1日 3:00 JST に前月以前のdraft明細をconfirmedに更新
 */
exports.confirmMonthlyStatements = onSchedule(
  {
    schedule: "0 18 1 * *", // UTC 18:00 = JST 3:00 翌日（1日）
    region: REGION,
    timeZone: "Asia/Tokyo",
  },
  async () => {
    try {
      const db = admin.firestore();
      const now = new Date();
      const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;

      const drafts = await db
        .collection("monthly_statements")
        .where("status", "==", "draft")
        .get();

      let confirmedCount = 0;
      const batch = db.batch();

      for (const doc of drafts.docs) {
        const data = doc.data();
        // 当月のdraftは変更しない
        if (data.month >= currentMonth) continue;

        batch.update(doc.ref, {
          status: "confirmed",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        confirmedCount++;
      }

      if (confirmedCount > 0) {
        await batch.commit();
      }

      logger.info("Monthly statements confirmed", { confirmedCount });
    } catch (e) {
      logger.error("confirmMonthlyStatements failed", e);
    }
  },
);
