#!/usr/bin/env node
/**
 * App Store スクリーンショット用デモデータ投入スクリプト
 *
 * テストデータを draft に変更し、リアルな建設・内装案件データを投入する。
 *
 * 使い方:
 *   cd functions
 *   node scripts/seed_demo_jobs.js
 */

const fs = require("fs");
const path = require("path");
const https = require("https");

const PROJECT_ID = "alba-work";
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// ── Firebase CLI トークン取得 ──
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

// ── REST API ヘルパー ──
function request(method, urlPath, token, body) {
  const url = urlPath.startsWith("http") ? urlPath : `${BASE_URL}/${urlPath}`;
  const parsed = new URL(url);
  const bodyStr = body ? JSON.stringify(body) : null;

  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: parsed.hostname,
      path: parsed.pathname + parsed.search,
      method,
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
        ...(bodyStr ? { "Content-Length": Buffer.byteLength(bodyStr) } : {}),
      },
    }, (res) => {
      let data = "";
      res.on("data", (chunk) => data += chunk);
      res.on("end", () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(data ? JSON.parse(data) : {});
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data.substring(0, 300)}`));
        }
      });
    });
    req.on("error", reject);
    if (bodyStr) req.write(bodyStr);
    req.end();
  });
}

async function listCollection(token, collection) {
  const results = [];
  let pageToken = "";
  do {
    const url = `${BASE_URL}/${collection}?pageSize=100${pageToken ? "&pageToken=" + pageToken : ""}`;
    const res = await request("GET", url, token);
    if (res.documents) results.push(...res.documents);
    pageToken = res.nextPageToken || "";
  } while (pageToken);
  return results;
}

async function patchDoc(token, docPath, fields) {
  return request("PATCH", docPath, token, { fields });
}

async function createDoc(token, collection, fields) {
  return request("POST", `${BASE_URL}/${collection}`, token, { fields });
}

// ── Firestore 型変換ヘルパー ──
const str = (v) => ({ stringValue: v });
const int = (v) => ({ integerValue: String(v) });
const dbl = (v) => ({ doubleValue: v });
const ts = (v) => ({ timestampValue: v instanceof Date ? v.toISOString() : v });
const arr = (items) => ({ arrayValue: { values: items } });
const bool = (v) => ({ booleanValue: v });

// ── リアル案件データ ──
const DEMO_JOBS = [
  {
    title: "新宿区 高層マンション内装リフォーム",
    location: "新宿区西新宿3丁目",
    prefecture: "東京都",
    price: 35000,
    date: "2026-03-20",
    description: "築15年の高層マンション（30階建て）の内装リフォーム工事です。壁紙の全面張替え、フローリングの上張り、キッチン周りのタイル施工を行います。\n\n【作業内容】\n・LDK + 寝室2部屋の壁紙張替え\n・フローリング上張り施工\n・キッチンバックパネル タイル貼り\n\n【必要スキル】\n・壁紙張替え経験3年以上\n・丁寧な仕上げができる方",
    category: "内装仕上",
    latitude: 35.6893,
    longitude: 139.6927,
    slots: 3,
    imageUrls: [
      "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80",
      "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&q=80",
    ],
    requiredQualifications: ["内装仕上施工技能士", "普通自動車免許"],
  },
  {
    title: "渋谷 オフィスビル原状回復工事",
    location: "渋谷区道玄坂2丁目",
    prefecture: "東京都",
    price: 28000,
    date: "2026-03-22",
    description: "渋谷駅徒歩5分のオフィスビル3フロア分の原状回復工事です。退去に伴う壁紙張替え、床材の補修、天井の塗装を行います。\n\n【工期】3月22日〜3月28日（7日間）\n\n【特記事項】\n・夜間作業なし（9:00-18:00）\n・エレベーター使用可",
    category: "原状回復",
    latitude: 35.6580,
    longitude: 139.7016,
    slots: 5,
    imageUrls: [
      "https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80",
      "https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=800&q=80",
    ],
    requiredQualifications: ["普通自動車免許"],
  },
  {
    title: "品川 タワーレジデンス フローリング施工",
    location: "港区港南2丁目",
    prefecture: "東京都",
    price: 42000,
    date: "2026-03-25",
    description: "品川駅直結の新築タワーマンション内装工事。最高級フローリング材の施工をお任せします。\n\n【対象】4LDK × 2戸\n【使用材】無垢フローリング（ウォールナット材）\n\n高い精度が求められる現場です。フローリング施工の実務経験がある方を歓迎します。",
    category: "床仕上",
    latitude: 35.6284,
    longitude: 139.7387,
    slots: 2,
    imageUrls: [
      "https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800&q=80",
      "https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800&q=80",
    ],
    requiredQualifications: ["床仕上施工技能士", "内装仕上施工技能士"],
  },
  {
    title: "六本木 商業施設 天井・照明リニューアル",
    location: "港区六本木6丁目",
    prefecture: "東京都",
    price: 38000,
    date: "2026-04-01",
    description: "六本木の大型商業施設内テナントの天井リニューアル工事。既存天井材の撤去、新規軽天下地の施工、ボード貼り、LED照明器具の取付けを行います。\n\n【作業時間】22:00〜翌6:00（夜間作業）\n※営業時間外の作業となります\n\n深夜割増あり。経験豊富な職人さんを募集中！",
    category: "天井仕上",
    latitude: 35.6627,
    longitude: 139.7311,
    slots: 4,
    imageUrls: [
      "https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=800&q=80",
    ],
    requiredQualifications: ["普通自動車免許"],
  },
  {
    title: "中目黒 カフェ新装オープン内装工事",
    location: "目黒区上目黒1丁目",
    prefecture: "東京都",
    price: 32000,
    date: "2026-04-05",
    description: "中目黒駅近くのカフェ新規出店に伴う内装工事一式。デザイナーの図面に基づき、温かみのある木質系の内装仕上げを行います。\n\n【作業内容】\n・無垢材カウンター取付\n・珪藻土塗り壁施工\n・タイル施工（床・壁）\n・木製棚取付\n\nおしゃれなカフェ空間を一緒に作りましょう！",
    category: "内装仕上",
    latitude: 35.6443,
    longitude: 139.6987,
    slots: 3,
    imageUrls: [
      "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&q=80",
      "https://images.unsplash.com/photo-1559329007-40df8a9345d8?w=800&q=80",
    ],
    requiredQualifications: [],
  },
  {
    title: "横浜みなとみらい マンション大規模修繕",
    location: "横浜市西区みなとみらい4丁目",
    prefecture: "神奈川県",
    price: 30000,
    date: "2026-04-10",
    description: "みなとみらい地区の大規模マンション修繕工事。共用部の壁紙張替えと塗装作業を担当していただきます。\n\n【期間】4月10日〜5月末（長期案件）\n【勤務】週5日 8:00-17:00\n\n長期で安定して働ける方を優遇します。",
    category: "塗装",
    latitude: 35.4580,
    longitude: 139.6326,
    slots: 6,
    imageUrls: [
      "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&q=80",
    ],
    requiredQualifications: ["塗装技能士", "普通自動車免許"],
  },
  {
    title: "銀座 ブティック店舗 高級内装改装",
    location: "中央区銀座5丁目",
    prefecture: "東京都",
    price: 45000,
    date: "2026-04-15",
    description: "銀座の高級ブティック店舗の改装工事。大理石調タイルの施工、特注什器の設置、間接照明の配線工事を行います。\n\n【求める人物像】\n・高級店舗の施工経験がある方\n・仕上がりの美しさにこだわれる方\n・チームワークを大切にできる方\n\n報酬は経験・スキルに応じて相談可。",
    category: "店舗内装",
    latitude: 35.6717,
    longitude: 139.7649,
    slots: 2,
    imageUrls: [
      "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80",
      "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=800&q=80",
    ],
    requiredQualifications: ["内装仕上施工技能士"],
  },
  {
    title: "目黒区 戸建て全面リノベーション",
    location: "目黒区自由が丘2丁目",
    prefecture: "東京都",
    price: 40000,
    date: "2026-04-20",
    description: "築25年の木造2階建て住宅の全面リノベーション。間取り変更に伴う内装工事全般を担当していただきます。\n\n【作業内容】\n・軽天下地組み\n・ボード貼り\n・クロス張替え\n・フローリング施工\n・建具取付け\n\nワンストップで対応できる多能工の方を歓迎！",
    category: "リノベーション",
    latitude: 35.6078,
    longitude: 139.6694,
    slots: 3,
    imageUrls: [
      "https://images.unsplash.com/photo-1600573472550-8090b5e0745e?w=800&q=80",
      "https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=800&q=80",
    ],
    requiredQualifications: ["内装仕上施工技能士", "普通自動車免許"],
  },
];

// ── メイン処理 ──
async function main() {
  console.log("🔑 Firebase CLI 認証トークンを取得中...");
  const token = await getAccessToken();
  console.log("✅ トークン取得成功\n");

  const now = new Date();

  // ── 1. 既存テストデータを draft に変更 ──
  console.log("=== 既存テストデータの確認 ===");
  const existingJobs = await listCollection(token, "jobs");
  console.log(`  既存案件数: ${existingJobs.length}`);

  let hiddenCount = 0;
  for (const doc of existingJobs) {
    const title = doc.fields?.title?.stringValue || "";
    if (title.includes("テスト") || title.includes("test") || title.includes("Test")) {
      const fullUrl = `https://firestore.googleapis.com/v1/${doc.name}`;
      await request("PATCH", fullUrl, token, {
        fields: {
          ...doc.fields,
          status: str("draft"),
        },
      });
      hiddenCount++;
      console.log(`  📝 draft に変更: "${title}"`);
    }
  }
  console.log(`  → ${hiddenCount}件のテストデータを非表示化\n`);

  // ── 2. リアルデモ案件を投入 ──
  console.log("=== リアル案件データの投入 ===");
  for (let i = 0; i < DEMO_JOBS.length; i++) {
    const job = DEMO_JOBS[i];
    // 作成日時をずらして順番を制御
    const createdAt = new Date(now.getTime() - (DEMO_JOBS.length - i) * 3600000);

    const fields = {
      title: str(job.title),
      location: str(job.location),
      prefecture: str(job.prefecture),
      price: int(job.price),
      date: str(job.date),
      description: str(job.description),
      category: str(job.category),
      status: str("published"),
      slots: int(job.slots),
      applicantCount: int(Math.floor(Math.random() * job.slots)),
      createdAt: ts(createdAt),
      updatedAt: ts(createdAt),
    };

    if (job.latitude) {
      fields.latitude = dbl(job.latitude);
      fields.longitude = dbl(job.longitude);
    }

    if (job.imageUrls && job.imageUrls.length > 0) {
      fields.imageUrl = str(job.imageUrls[0]);
      fields.imageUrls = arr(job.imageUrls.map(u => str(u)));
    }

    if (job.requiredQualifications && job.requiredQualifications.length > 0) {
      fields.requiredQualifications = arr(job.requiredQualifications.map(q => str(q)));
    }

    await createDoc(token, "jobs", fields);
    console.log(`  ✅ ${job.title} — ¥${job.price.toLocaleString()}/日`);
  }
  console.log(`  → ${DEMO_JOBS.length}件の案件を投入完了\n`);

  // ── 3. stats/realtime を更新 ──
  console.log("=== 統計データ更新 ===");
  const totalJobs = existingJobs.length - hiddenCount + DEMO_JOBS.length;
  await patchDoc(token, "stats/realtime", {
    totalJobs: int(totalJobs),
    totalApplications: int(87),
    totalUsers: int(156),
    pendingApplications: int(5),
    updatedAt: ts(now),
  });
  console.log(`  ✅ stats/realtime — 案件${totalJobs}, 応募87, ユーザー156\n`);

  console.log("🎉 デモデータ投入完了！");
  console.log("   アプリを開いてリフレッシュすると、リアルな案件が表示されます。");
  console.log("   地図検索でも東京エリアにピンが表示されます。");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ エラー:", err.message || err);
    process.exit(1);
  });
