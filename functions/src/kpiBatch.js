const admin = require("firebase-admin");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

const REGION = "asia-northeast1";

/**
 * コレクションのドキュメント数をカウント
 */
async function countCollection(collectionName, filters = []) {
  let query = admin.firestore().collection(collectionName);
  for (const [field, op, value] of filters) {
    query = query.where(field, op, value);
  }
  const snapshot = await query.count().get();
  return snapshot.data().count;
}

/**
 * earnings コレクションの合計金額を算出
 */
async function sumEarnings(filters = []) {
  let query = admin.firestore().collection("earnings");
  for (const [field, op, value] of filters) {
    query = query.where(field, op, value);
  }
  const snapshot = await query.get();
  let total = 0;
  snapshot.docs.forEach((doc) => {
    const amount = doc.data().amount;
    if (Number.isInteger(amount)) {
      total += amount;
    }
  });
  return total;
}

/**
 * 日次 KPI 集計 (毎日 1:00 JST)
 *
 * 集計項目:
 * - newUsers: 新規ユーザー数（当日）
 * - newJobs: 新規求人数（当日）
 * - newApplications: 新規応募数（当日）
 * - dailyEarnings: 当日の売上合計
 * - activeChats: アクティブチャット数（当日メッセージあり）
 */
exports.dailyKpiAggregation = onSchedule(
  {
    schedule: "0 1 * * *",
    region: REGION,
    timeZone: "Asia/Tokyo",
  },
  async () => {
    try {
      const now = new Date();
      // 前日の 00:00:00 〜 23:59:59 (JST)
      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);
      const dayStart = new Date(yesterday.getFullYear(), yesterday.getMonth(), yesterday.getDate());
      const dayEnd = new Date(dayStart);
      dayEnd.setDate(dayEnd.getDate() + 1);

      const startTs = admin.firestore.Timestamp.fromDate(dayStart);
      const endTs = admin.firestore.Timestamp.fromDate(dayEnd);

      const dateKey = `${dayStart.getFullYear()}-${String(dayStart.getMonth() + 1).padStart(2, "0")}-${String(dayStart.getDate()).padStart(2, "0")}`;

      const [newUsers, newJobs, newApplications, dailyEarnings] = await Promise.all([
        countCollection("profiles", [["createdAt", ">=", startTs], ["createdAt", "<", endTs]]),
        countCollection("jobs", [["createdAt", ">=", startTs], ["createdAt", "<", endTs]]),
        countCollection("applications", [["createdAt", ">=", startTs], ["createdAt", "<", endTs]]),
        sumEarnings([["payoutConfirmedAt", ">=", startTs], ["payoutConfirmedAt", "<", endTs]]),
      ]);

      // アクティブチャット数（updatedAt が当日のチャット）
      const activeChats = await countCollection("chats", [
        ["updatedAt", ">=", startTs],
        ["updatedAt", "<", endTs],
      ]);

      const kpiData = {
        dateKey,
        newUsers,
        newJobs,
        newApplications,
        dailyEarnings,
        activeChats,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await admin.firestore().collection("kpi_daily").doc(dateKey).set(kpiData);

      logger.info("Daily KPI aggregation completed", { dateKey, ...kpiData });
    } catch (e) {
      logger.error("Daily KPI aggregation failed", e);
    }
  },
);

/**
 * 月次 KPI 集計 (毎月1日 2:00 JST)
 *
 * 集計項目:
 * - mau: 月間アクティブユーザー数 (概算: 当月にログインしたプロフィール数)
 * - monthlyEarnings: 月間売上合計
 * - jobFillRate: 求人充足率（応募がある求人 / 全求人）
 * - totalJobs: 月末時点の総求人数
 * - totalUsers: 月末時点の総ユーザー数
 * - totalApplications: 月間の総応募数
 */
exports.monthlyKpiAggregation = onSchedule(
  {
    schedule: "0 2 1 * *",
    region: REGION,
    timeZone: "Asia/Tokyo",
  },
  async () => {
    try {
      const now = new Date();
      // 前月
      const prevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const monthStart = new Date(prevMonth.getFullYear(), prevMonth.getMonth(), 1);
      const monthEnd = new Date(prevMonth.getFullYear(), prevMonth.getMonth() + 1, 1);

      const startTs = admin.firestore.Timestamp.fromDate(monthStart);
      const endTs = admin.firestore.Timestamp.fromDate(monthEnd);

      const monthKey = `${monthStart.getFullYear()}-${String(monthStart.getMonth() + 1).padStart(2, "0")}`;

      const [totalUsers, totalJobs, monthlyApplications, monthlyEarnings] = await Promise.all([
        countCollection("profiles"),
        countCollection("jobs"),
        countCollection("applications", [["createdAt", ">=", startTs], ["createdAt", "<", endTs]]),
        sumEarnings([["payoutConfirmedAt", ">=", startTs], ["payoutConfirmedAt", "<", endTs]]),
      ]);

      // MAU: 当月に updatedAt があるプロフィール数（ログイン時に updatedAt を更新する前提）
      const mau = await countCollection("profiles", [
        ["updatedAt", ">=", startTs],
        ["updatedAt", "<", endTs],
      ]);

      // 求人充足率: 応募がある求人数 / 全求人数
      // ※ 簡易実装: 当月応募の jobId ユニーク数
      const appsSnap = await admin.firestore().collection("applications")
        .where("createdAt", ">=", startTs)
        .where("createdAt", "<", endTs)
        .select("jobId")
        .get();
      const uniqueJobIds = new Set(appsSnap.docs.map((d) => d.data().jobId));
      const jobFillRate = totalJobs > 0 ? Math.round((uniqueJobIds.size / totalJobs) * 100) : 0;

      const kpiData = {
        monthKey,
        mau,
        monthlyEarnings,
        jobFillRate,
        totalJobs,
        totalUsers,
        totalApplications: monthlyApplications,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await admin.firestore().collection("kpi_monthly").doc(monthKey).set(kpiData);

      logger.info("Monthly KPI aggregation completed", { monthKey, ...kpiData });
    } catch (e) {
      logger.error("Monthly KPI aggregation failed", e);
    }
  },
);
