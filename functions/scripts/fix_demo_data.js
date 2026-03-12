#!/usr/bin/env node
/**
 * デモデータ修正スクリプト
 * 1. デモ案件に ownerId を追加（「ownerIdなし」バッジ消去）
 * 2. チャットデータをリアルな内容に更新
 */

const fs = require("fs");
const path = require("path");
const https = require("https");

const PROJECT_ID = "alba-work";
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const ADMIN_UID = "5AeMBYb9PifYVUWMf4lSdCjuM1s1";

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

function request(method, url, token, body) {
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
          reject(new Error(`HTTP ${res.statusCode}: ${data.substring(0, 500)}`));
        }
      });
    });
    req.on("error", reject);
    if (bodyStr) req.write(bodyStr);
    req.end();
  });
}

const str = (v) => ({ stringValue: v });
const int = (v) => ({ integerValue: String(v) });
const ts = (v) => ({ timestampValue: v instanceof Date ? v.toISOString() : v });

async function main() {
  console.log("🔑 Firebase CLI 認証トークンを取得中...");
  const token = await getAccessToken();
  console.log("✅ トークン取得成功\n");

  // ── 1. 公開中の案件に ownerId を追加 ──
  console.log("=== 案件に ownerId を追加 ===");
  const jobsUrl = `${BASE_URL}/jobs?pageSize=100`;
  const jobsRes = await request("GET", jobsUrl, token);
  const jobs = jobsRes.documents || [];

  let updatedCount = 0;
  for (const doc of jobs) {
    const status = doc.fields?.status?.stringValue;
    const ownerId = doc.fields?.ownerId?.stringValue;

    // published で ownerId がないものに追加
    if (status === "published" && (!ownerId || ownerId === "")) {
      const fullUrl = `https://firestore.googleapis.com/v1/${doc.name}`;
      await request("PATCH", fullUrl, token, {
        fields: {
          ...doc.fields,
          ownerId: str(ADMIN_UID),
        },
      });
      const title = doc.fields?.title?.stringValue || "不明";
      console.log(`  ✅ ownerId追加: "${title}"`);
      updatedCount++;
    }
  }
  console.log(`  → ${updatedCount}件の案件を更新\n`);

  // ── 2. チャットデータの更新 ──
  console.log("=== チャットデータの更新 ===");

  // チャット一覧を取得
  const chatsUrl = `${BASE_URL}/chats?pageSize=100`;
  const chatsRes = await request("GET", chatsUrl, token);
  const chats = chatsRes.documents || [];

  // メッセージがある最初のチャットを更新
  const targetChatId = "2rZmhDIlSB4PZ8TtYVSX";

  // チャットドキュメントのタイトルを更新
  for (const doc of chats) {
    const docId = doc.name.split("/").pop();
    if (docId === targetChatId) {
      const fullUrl = `https://firestore.googleapis.com/v1/${doc.name}`;
      await request("PATCH", fullUrl, token, {
        fields: {
          ...doc.fields,
          titleSnapshot: str("新宿区 高層マンション内装リフォーム"),
          lastMessageText: str("承知しました。当日は8時に現場集合でお願いします。"),
          lastMessageAt: ts(new Date()),
        },
      });
      console.log(`  ✅ チャットタイトル更新: "新宿区 高層マンション内装リフォーム"`);
      break;
    }
  }

  // メッセージの更新
  const messagesUrl = `${BASE_URL}/chats/${targetChatId}/messages?pageSize=20&orderBy=createdAt`;
  let messagesRes;
  try {
    messagesRes = await request("GET", messagesUrl, token);
  } catch (e) {
    // orderBy が使えない場合はなしで取得
    const fallbackUrl = `${BASE_URL}/chats/${targetChatId}/messages?pageSize=20`;
    messagesRes = await request("GET", fallbackUrl, token);
  }
  const messages = messagesRes.documents || [];

  // リアルなメッセージ内容
  const realisticMessages = [
    { text: "新宿区のマンションリフォーム案件に応募させていただきました。壁紙張替えの経験が5年あります。", sender: "applicant" },
    { text: "ご応募ありがとうございます。経歴を拝見しました。クロス施工の実績が豊富ですね。", sender: "admin" },
    { text: "はい、マンションの内装工事を中心に施工してきました。LDKの壁紙は得意です。", sender: "applicant" },
    { text: "素晴らしいですね。3月20日からの現場ですが、ご都合いかがでしょうか？", sender: "admin" },
    { text: "はい、問題ありません。朝8時集合で大丈夫です。", sender: "applicant" },
    { text: "では正式に採用とさせていただきます。詳細は後ほどお送りします。", sender: "admin" },
    { text: "承知しました。当日は8時に現場集合でお願いします。", sender: "admin" },
  ];

  console.log(`  メッセージ数: ${messages.length}`);

  for (let i = 0; i < messages.length && i < realisticMessages.length; i++) {
    const doc = messages[i];
    const msgData = realisticMessages[i];
    const fullUrl = `https://firestore.googleapis.com/v1/${doc.name}`;

    // senderUid は既存のものを使用（applicant/admin の判別はメッセージの方向で決まる）
    const existingSenderUid = doc.fields?.senderUid?.stringValue;
    const imageUrl = doc.fields?.imageUrl?.stringValue;

    const fields = {
      ...doc.fields,
      text: str(msgData.text),
      messageType: str("text"),
    };

    // 画像メッセージだったものはテキストに変更
    if (imageUrl) {
      delete fields.imageUrl;
    }

    await request("PATCH", fullUrl, token, { fields });
    console.log(`  ✅ メッセージ${i + 1}: "${msgData.text.substring(0, 30)}..."`);
  }

  console.log(`\n🎉 デモデータの修正完了！`);
  console.log("   アプリをリフレッシュしてください。");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ エラー:", err.message || err);
    process.exit(1);
  });
