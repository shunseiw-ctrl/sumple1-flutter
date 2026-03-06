const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const path = require("path");

/**
 * verifyFaceMatch — 身分証の顔写真と自撮り写真を照合する onCall CF
 *
 * - face-api.js で128次元特徴量を抽出
 * - Euclidean distance で類似度スコアを計算
 * - score >= 80 → matched: true
 */
exports.verifyFaceMatch = onCall(
  {
    region: "asia-northeast1",
    memory: "1GiB",
    timeoutSeconds: 120,
    maxInstances: 5,
  },
  async (request) => {
    // 認証チェック
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "認証が必要です");
    }

    const callerUid = request.auth.uid;
    const targetUid = request.data?.uid || callerUid;

    // 自分自身の照合のみ許可
    if (callerUid !== targetUid) {
      throw new HttpsError(
        "permission-denied",
        "自分自身の顔照合のみ実行できます"
      );
    }

    logger.info("顔照合開始", { uid: targetUid });

    try {
      // Firestoreから identity_verification ドキュメントを取得
      const docRef = admin
        .firestore()
        .collection("identity_verification")
        .doc(targetUid);
      const docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw new HttpsError(
          "not-found",
          "本人確認ドキュメントが見つかりません"
        );
      }

      const data = docSnap.data();
      const idPhotoUrl = data.idPhotoUrl;
      const selfieUrl = data.selfieUrl;

      if (!idPhotoUrl || !selfieUrl) {
        throw new HttpsError(
          "failed-precondition",
          "身分証写真または自撮り写真が未アップロードです"
        );
      }

      // face-api.js の動的ロード（コールドスタート最適化）
      const faceapi = require("@vladmandic/face-api");
      const tf = require("@tensorflow/tfjs-node");
      const canvas = require("canvas");
      const fetch = require("node-fetch");

      // canvas環境をセットアップ
      const { Canvas, Image, ImageData } = canvas;
      faceapi.env.monkeyPatch({ Canvas, Image, ImageData, fetch });

      // モデルの読み込み
      const modelsPath = path.join(__dirname, "..", "models");
      await Promise.all([
        faceapi.nets.ssdMobilenetv1.loadFromDisk(modelsPath),
        faceapi.nets.faceLandmark68Net.loadFromDisk(modelsPath),
        faceapi.nets.faceRecognitionNet.loadFromDisk(modelsPath),
      ]);

      // 画像をダウンロードしてcanvasに変換
      const [idPhotoCanvas, selfieCanvas] = await Promise.all([
        loadImageFromUrl(idPhotoUrl, canvas, fetch),
        loadImageFromUrl(selfieUrl, canvas, fetch),
      ]);

      // 顔検出 + 特徴量抽出
      const [idDetection, selfieDetection] = await Promise.all([
        faceapi
          .detectSingleFace(idPhotoCanvas, new faceapi.SsdMobilenetv1Options({ minConfidence: 0.3 }))
          .withFaceLandmarks()
          .withFaceDescriptor(),
        faceapi
          .detectSingleFace(selfieCanvas, new faceapi.SsdMobilenetv1Options({ minConfidence: 0.5 }))
          .withFaceLandmarks()
          .withFaceDescriptor(),
      ]);

      if (!idDetection) {
        logger.warn("身分証から顔を検出できませんでした", { uid: targetUid });
        const result = { score: 0, matched: false, error: "id_face_not_found" };
        await writeResult(docRef, result);
        return result;
      }

      if (!selfieDetection) {
        logger.warn("自撮り写真から顔を検出できませんでした", { uid: targetUid });
        const result = { score: 0, matched: false, error: "selfie_face_not_found" };
        await writeResult(docRef, result);
        return result;
      }

      // Euclidean distance 計算
      const distance = faceapi.euclideanDistance(
        idDetection.descriptor,
        selfieDetection.descriptor
      );

      // スコア変換: distance 0→100, distance 1.5→0
      const score = Math.round(Math.max(0, (1 - distance / 1.5) * 100));
      const matched = score >= 80;

      logger.info("顔照合完了", {
        uid: targetUid,
        distance: distance.toFixed(4),
        score,
        matched,
      });

      const result = { score, matched };
      await writeResult(docRef, result);

      // TF.jsのメモリ解放
      tf.disposeVariables();

      return result;
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      logger.error("顔照合で予期せぬエラー", { uid: targetUid, error: e.message });
      throw new HttpsError("internal", "顔照合処理に失敗しました");
    }
  }
);

/**
 * URLから画像をダウンロードしてcanvasに変換
 */
async function loadImageFromUrl(url, canvasLib, fetchLib) {
  const response = await fetchLib(url);
  if (!response.ok) {
    throw new Error(`画像のダウンロードに失敗: ${response.status}`);
  }
  const buffer = await response.buffer();
  const img = await canvasLib.loadImage(buffer);
  const cvs = canvasLib.createCanvas(img.width, img.height);
  const ctx = cvs.getContext("2d");
  ctx.drawImage(img, 0, 0);
  return cvs;
}

/**
 * Firestoreに顔照合結果を書き込み（Admin SDK）
 */
async function writeResult(docRef, result) {
  const updateData = {
    faceMatchScore: result.score,
    faceMatchedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  await docRef.update(updateData);
}
