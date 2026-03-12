#!/usr/bin/env node
/**
 * KPI テストデータ シードスクリプト
 *
 * 使い方:
 *   cd functions
 *   node scripts/seed_kpi_data.js
 *
 * Firebase CLIの認証情報を使用してFirestoreに直接アクセスします。
 */

const { Firestore } = require("@google-cloud/firestore");
const fs = require("fs");
const path = require("path");
const https = require("https");

const PROJECT_ID = "alba-work";

/**
 * Firebase CLIの保存済みトークンからアクセストークンを取得
 */
async function getAccessToken() {
  const configPath = path.join(
    process.env.HOME || process.env.USERPROFILE,
    ".config/configstore/firebase-tools.json"
  );

  const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
  const refreshToken = config.tokens.refresh_token;
  const clientId = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com";
  const clientSecret = "j9iVZfS8kkCEFUPaAeJV0sAi";

  return new Promise((resolve, reject) => {
    const postData = `grant_type=refresh_token&client_id=${clientId}&client_secret=${clientSecret}&refresh_token=${refreshToken}`;
    const req = https.request({
      hostname: "oauth2.googleapis.com",
      path: "/token",
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Content-Length": postData.length,
      },
    }, (res) => {
      let data = "";
      res.on("data", (chunk) => data += chunk);
      res.on("end", () => {
        const parsed = JSON.parse(data);
        if (parsed.access_token) resolve(parsed.access_token);
        else reject(new Error("トークン取得失敗: " + data));
      });
    });
    req.on("error", reject);
    req.write(postData);
    req.end();
  });
}

async function seedKpiData() {
  console.log("🔑 Firebase CLI 認証トークンを取得中...");
  const accessToken = await getAccessToken();

  const db = new Firestore({
    projectId: PROJECT_ID,
    credentials: {
      client_email: "firebase-cli@local",
      private_key: "unused",
    },
    // アクセストークンを直接提供
  });

  // Firestore REST APIで直接書き込み
  const baseUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

  async function patchDoc(docPath, fields) {
    const url = `${baseUrl}/${docPath}`;
    const body = JSON.stringify({ fields });

    return new Promise((resolve, reject) => {
      const req = https.request(url, {
        method: "PATCH",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(body),
        },
      }, (res) => {
        let data = "";
        res.on("data", (chunk) => data += chunk);
        res.on("end", () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(JSON.parse(data));
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${data}`));
          }
        });
      });
      req.on("error", reject);
      req.write(body);
      req.end();
    });
  }

  const now = new Date();
  const ts = now.toISOString();

  // ── 1. stats/realtime ──
  console.log("\n=== stats/realtime ===");
  await patchDoc("stats/realtime", {
    totalJobs: { integerValue: "24" },
    totalApplications: { integerValue: "87" },
    totalUsers: { integerValue: "156" },
    pendingApplications: { integerValue: "5" },
    updatedAt: { timestampValue: ts },
  });
  console.log("✅ stats/realtime — 案件24, 応募87, ユーザー156, 未処理5");

  // ── 2. kpi_daily (直近7日分) ──
  console.log("\n=== kpi_daily (直近7日分) ===");
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(d.getDate() - i);
    const dateKey = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;

    const newApplications = Math.floor(Math.random() * 12) + 2;
    const dailyEarnings = Math.floor(Math.random() * 50000) + 10000;
    const newUsers = Math.floor(Math.random() * 8) + 1;
    const newJobs = Math.floor(Math.random() * 5) + 1;
    const activeChats = Math.floor(Math.random() * 15) + 3;

    await patchDoc(`kpi_daily/${dateKey}`, {
      dateKey: { stringValue: dateKey },
      newApplications: { integerValue: String(newApplications) },
      dailyEarnings: { integerValue: String(dailyEarnings) },
      newUsers: { integerValue: String(newUsers) },
      newJobs: { integerValue: String(newJobs) },
      activeChats: { integerValue: String(activeChats) },
      createdAt: { timestampValue: ts },
    });
    console.log(`✅ kpi_daily/${dateKey} — 応募${newApplications}件, 売上¥${dailyEarnings.toLocaleString()}`);
  }

  // ── 3. kpi_monthly (当月) ──
  const currentMonthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
  console.log(`\n=== kpi_monthly/${currentMonthKey} (当月) ===`);
  await patchDoc(`kpi_monthly/${currentMonthKey}`, {
    monthKey: { stringValue: currentMonthKey },
    mau: { integerValue: "89" },
    monthlyEarnings: { integerValue: "1250000" },
    jobFillRate: { doubleValue: 0.72 },
    totalJobs: { integerValue: "24" },
    totalUsers: { integerValue: "156" },
    totalApplications: { integerValue: "42" },
    createdAt: { timestampValue: ts },
  });
  console.log(`✅ kpi_monthly/${currentMonthKey} — MAU 89, 売上¥1,250,000, 充足率72%`);

  // ── 4. kpi_monthly (前月) ──
  const prevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const prevMonthKey = `${prevMonth.getFullYear()}-${String(prevMonth.getMonth() + 1).padStart(2, "0")}`;
  console.log(`\n=== kpi_monthly/${prevMonthKey} (前月) ===`);
  await patchDoc(`kpi_monthly/${prevMonthKey}`, {
    monthKey: { stringValue: prevMonthKey },
    mau: { integerValue: "67" },
    monthlyEarnings: { integerValue: "980000" },
    jobFillRate: { doubleValue: 0.58 },
    totalJobs: { integerValue: "18" },
    totalUsers: { integerValue: "132" },
    totalApplications: { integerValue: "35" },
    createdAt: { timestampValue: ts },
  });
  console.log(`✅ kpi_monthly/${prevMonthKey} — MAU 67, 売上¥980,000, 充足率58%`);

  console.log("\n🎉 全KPIテストデータの投入完了！");
  console.log("   アプリのダッシュボードを下に引いてリフレッシュしてください。");
}

seedKpiData()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ エラー:", err.message || err);
    process.exit(1);
  });
