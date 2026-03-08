# ALBAWORK v1.0.0 リリースガイド

## 前提条件

- [ ] Apple Developer Program 加入済み ($99/年)
- [ ] Google Play デベロッパーアカウント作成済み ($25)
- [ ] Android キーストア（keystore.jks）が作成済み
- [ ] Match 用プライベートリポジトリ（certificates）が作成済み

---

## GitHub Secrets 設定手順

リポジトリの Settings > Secrets and variables > Actions > New repository secret から設定。

### Android 署名（4個）

| Secret 名 | 値の取得方法 |
|-----------|-------------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i keystore.jks` の出力 |
| `ANDROID_KEYSTORE_PASSWORD` | キーストア作成時のパスワード |
| `ANDROID_KEY_PASSWORD` | キー作成時のパスワード |
| `ANDROID_KEY_ALIAS` | キー作成時のエイリアス名 |

**キーストア未作成の場合:**
```bash
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias albawork
```

### Google Play API（1個）

| Secret 名 | 値の取得方法 |
|-----------|-------------|
| `GOOGLE_PLAY_JSON_KEY_BASE64` | Google Cloud Console > IAM > サービスアカウント > JSON キー作成 > `base64 -i key.json` |

**手順:**
1. Google Cloud Console で「Google Play Android Developer API」を有効化
2. サービスアカウント作成（ロール: 編集者）
3. JSON キーをダウンロード
4. Google Play Console > 設定 > API アクセス でサービスアカウントをリンク
5. `base64 -i <downloaded-key>.json` の出力をSecret に設定

### iOS 署名 - Match（2個）

| Secret 名 | 値の取得方法 |
|-----------|-------------|
| `MATCH_GIT_URL` | Match 用プライベートリポジトリのURL（例: `https://github.com/shunseiw-ctrl/certificates.git`） |
| `MATCH_PASSWORD` | 任意のパスワード（Match暗号化用） |

**Match 初期セットアップ（ローカルで1回実行）:**
```bash
cd ios
bundle exec fastlane match init
bundle exec fastlane match appstore
```

### App Store Connect API（4個）

| Secret 名 | 値の取得方法 |
|-----------|-------------|
| `APPLE_APP_ID` | App Store Connect > アプリ > 一般 > App情報 > Apple ID |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect > ユーザとアクセス > 統合 > キー > キーID |
| `APP_STORE_CONNECT_ISSUER_ID` | 同上ページの Issuer ID |
| `APP_STORE_CONNECT_API_KEY` | .p8 ファイルの中身（`-----BEGIN PRIVATE KEY-----` から `-----END PRIVATE KEY-----` まで） |

**手順:**
1. App Store Connect > ユーザとアクセス > 統合 > App Store Connect API
2. 「キーを生成」> 名前入力 > ロール: App Manager
3. キーID、Issuer ID をメモ
4. .p8 ファイルをダウンロード（1回しかダウンロード不可）
5. `cat AuthKey_XXXXXXXX.p8` の出力をSecret に設定

### Firebase（4個）

| Secret 名 | 値の取得方法 |
|-----------|-------------|
| `GOOGLE_SERVICE_INFO_PLIST` | Firebase Console > プロジェクト設定 > iOS アプリ > `GoogleService-Info.plist` > `base64 -i GoogleService-Info.plist` |
| `GOOGLE_SERVICES_JSON` | Firebase Console > プロジェクト設定 > Android アプリ > `google-services.json` > `base64 -i google-services.json` |
| `FIREBASE_SERVICE_ACCOUNT_STAGING` | GCP > IAM > サービスアカウント（alba-work-staging）> JSON キー |
| `FIREBASE_SERVICE_ACCOUNT_PRODUCTION` | GCP > IAM > サービスアカウント（alba-work）> JSON キー |

---

## Secret 設定確認

全15個の Secret が設定されたら確認:
```bash
gh secret list
```

期待される出力:
```
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
APPLE_APP_ID
APP_STORE_CONNECT_API_KEY
APP_STORE_CONNECT_API_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
FIREBASE_SERVICE_ACCOUNT_PRODUCTION
FIREBASE_SERVICE_ACCOUNT_STAGING
FIREBASE_TOKEN
GOOGLE_PLAY_JSON_KEY_BASE64
GOOGLE_SERVICE_INFO_PLIST
GOOGLE_SERVICES_JSON
MATCH_GIT_URL
MATCH_PASSWORD
```

---

## リリースフロー

### 1. ベータテスト配信
```bash
gh release create v1.0.0-beta.1 \
  --title "v1.0.0-beta.1 - ALBAWORK ベータテスト" \
  --notes "初回ベータテスト版"
```
→ GitHub Actions が自動で TestFlight + Google Play Internal にデプロイ

### 2. ベータテスト
- TestFlight: App Store Connect でテスターの Apple ID を追加
- Google Play: Play Console でテスターのメールアドレスを追加

### 3. 本番リリース
```bash
# iOS
cd ios && bundle exec fastlane release

# Android
cd android && bundle exec fastlane promote_to_production
```
