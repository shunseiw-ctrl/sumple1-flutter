# デプロイメントガイド

## 環境構成

ALBAWORK は 2 つの環境を使用します:

| 環境 | Firebase プロジェクト | ブランチ |
|------|---------------------|---------|
| Staging | alba-work-staging | staging |
| Production | alba-work | main |

## 前提条件

1. Firebase CLI インストール済み
2. 適切な Firebase プロジェクトへのアクセス権
3. Flutter SDK 3.8+
4. Node.js 22+
5. Fastlane（ストアデプロイ時）

## Cloud Functions デプロイ

### Staging

```bash
firebase use alba-work-staging
cd functions && npm install
firebase deploy --only functions
```

### Production

```bash
firebase use alba-work
cd functions && npm install
firebase deploy --only functions
```

### 個別 Function のデプロイ

```bash
firebase deploy --only functions:deleteUserData
firebase deploy --only functions:exportUserData
firebase deploy --only functions:onAuditJobWrite,functions:onAuditApplicationWrite
```

## Firestore ルールデプロイ

```bash
firebase deploy --only firestore:rules
```

## Flutter アプリビルド

### Android

```bash
# APK ビルド
flutter build apk --release

# App Bundle（Play Store 用）
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## Fastlane（ストアデプロイ）

### Android

```bash
cd android
bundle exec fastlane deploy
```

### iOS

```bash
cd ios
bundle exec fastlane deploy
```

## 環境変数

### Cloud Functions 環境変数

```bash
# LINE OAuth
firebase functions:config:set line.channel_id="..." line.channel_secret="..."

# Stripe
firebase functions:config:set stripe.secret_key="..." stripe.webhook_secret="..."

# 設定確認
firebase functions:config:get
```

### Flutter 環境切り替え

`lib/core/config/app_environment.dart` で環境を制御:
- `AppConfig.firebaseOptions` が環境に応じた Firebase 設定を返却
- ビルド時のフレーバーで切り替え

## CI/CD パイプライン

GitHub Actions（`.github/workflows/`）:

1. **テスト**: PR 時に自動実行
   - `flutter analyze`
   - `flutter test`
   - `cd functions && npm test`

2. **Staging デプロイ**: `staging` ブランチへのマージ時
   - Cloud Functions デプロイ
   - Firestore ルールデプロイ

3. **Production デプロイ**: `main` ブランチへのマージ時
   - Cloud Functions デプロイ
   - Firestore ルールデプロイ

## ロールバック手順

### Cloud Functions ロールバック

```bash
# デプロイ履歴確認
firebase functions:log --only <functionName>

# 前バージョンに戻す場合は、git で該当コミットに戻してから再デプロイ
git log --oneline -10
git checkout <commit-hash> -- functions/
firebase deploy --only functions
```

### Firestore ルールロールバック

```bash
git checkout <commit-hash> -- firestore.rules
firebase deploy --only firestore:rules
```

### アプリロールバック

- Play Store: 管理コンソールから前バージョンにロールバック
- App Store: 前バージョンを「現在のバージョン」に設定

## トラブルシューティング

### デプロイ失敗時

1. `firebase login` でログイン状態を確認
2. `firebase use` で正しいプロジェクトを選択しているか確認
3. `node_modules` を削除して `npm install` を再実行
4. Firebase CLI を最新に更新: `npm install -g firebase-tools`

### Functions のメモリ/タイムアウト

`functions/index.js` の `setGlobalOptions`:
```js
setGlobalOptions({ maxInstances: 10 });
```

個別の Function で上書き可能:
```js
exports.heavyFunction = onCall(
  { region: "asia-northeast1", memory: "512MiB", timeoutSeconds: 120 },
  async (request) => { ... }
);
```
