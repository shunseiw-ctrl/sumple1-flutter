# ALBAWORK

建設業界向け求人マッチングアプリ。求職者と企業をリアルタイムでつなぎ、応募から出退勤管理・支払いまでをワンストップで提供します。

## 機能一覧

### 求職者向け
- 求人検索・閲覧（都道府県・日付フィルタ）
- ワンタップ応募
- リアルタイムチャット
- QR/GPS 出退勤
- 売上・支払い履歴
- お気に入り管理
- プッシュ通知

### 企業（管理者）向け
- 求人作成・編集・削除
- 案件・応募統合管理（SegmentedButton切替: 案件管理/応募者管理、WorkPage風7タブ）
- 統合承認センター（資格/即金申請/eKYC本人確認を1タブに集約、未処理バッジ表示）
- ワーカー管理（稼働一覧/日報管理/検査管理のサブナビ構成）
- 職人詳細（プロフィール・応募履歴・資格情報）
- KPI ダッシュボード（リアルタイム統計 + 7日間トレンド + 月次KPI + 前月比）
- チャット
- シフト・QRコード管理
- 支払い管理（Stripe Connect）
- 管理者設定（テーマ切替・通知設定・ログアウト）
- 評価システム

### コンプライアンス
- アカウント削除（個人情報保護法/Apple 5.1.1 準拠）
- データエクスポート（開示請求権対応）
- 利用規約・プライバシーポリシー同意トラッキング
- 監査ログ（管理者操作の追跡）
- アクセシビリティ（Semantics 対応）

## アーキテクチャ

```
lib/
├── core/
│   ├── config/        # 環境設定（staging/production）
│   ├── constants/     # カラー、テキストスタイル、スペーシング等
│   ├── enums/         # UserRole 等
│   ├── services/      # ビジネスロジック（Auth, Chat, Payment 等）
│   └── utils/         # ロガー、エラーハンドラ、バリデーション
├── data/
│   └── models/        # データモデル（Job, Application, Chat 等）
├── l10n/              # 国際化（ARB ファイル）
├── pages/             # 画面ウィジェット
└── presentation/
    ├── pages/         # ゲスト用ページ
    └── widgets/       # 共通ウィジェット

functions/
├── src/               # Cloud Functions（個別モジュール）
│   ├── accountDeletion.js
│   ├── auditLog.js
│   ├── counters.js
│   ├── dataExport.js
│   ├── distributedCounter.js
│   ├── kpiBatch.js
│   ├── lineAuth.js
│   ├── notifications.js
│   ├── ratings.js
│   └── stripe.js
├── tests/             # Jest テスト
└── index.js           # エントリーポイント
```

## セットアップ

### 前提条件
- Flutter SDK 3.8+
- Node.js 22+
- Firebase CLI
- Xcode（iOS ビルド）
- Android Studio（Android ビルド）

### インストール

```bash
# Flutter 依存関係
flutter pub get

# Cloud Functions 依存関係
cd functions && npm install
```

### 環境設定

Firebase プロジェクトの設定:
```bash
# Firebase CLI ログイン
firebase login

# プロジェクト選択
firebase use <project-id>
```

環境変数（Cloud Functions）:
```bash
firebase functions:config:set \
  line.channel_id="YOUR_LINE_CHANNEL_ID" \
  line.channel_secret="YOUR_LINE_CHANNEL_SECRET" \
  stripe.secret_key="YOUR_STRIPE_SECRET_KEY" \
  stripe.webhook_secret="YOUR_STRIPE_WEBHOOK_SECRET"
```

## テスト

### Flutter テスト
```bash
# 全テスト実行
flutter test

# カバレッジ付き
flutter test --coverage

# 特定テスト
flutter test test/unit/models/
flutter test test/widget/
```

### Cloud Functions テスト
```bash
cd functions

# 全テスト実行
npm test

# Firestore ルールテスト（エミュレータ必要）
npm run test:rules
```

### 静的解析
```bash
flutter analyze
```

## CI/CD

GitHub Actions を使用:
- **staging**: `staging` ブランチへのプッシュでデプロイ
- **production**: `main` ブランチへのプッシュでデプロイ

詳細は `docs/DEPLOYMENT.md` を参照。

## 技術スタック

| カテゴリ | 技術 |
|---------|------|
| フロントエンド | Flutter (Dart) |
| バックエンド | Firebase (Firestore, Auth, Functions, Storage) |
| 決済 | Stripe Connect |
| 認証 | Firebase Auth + LINE OAuth |
| 通知 | FCM (Firebase Cloud Messaging) |
| 監視 | Firebase Analytics, Crashlytics, Performance |
| セキュリティ | Firebase App Check |
| CI/CD | GitHub Actions + Fastlane |
| テスト | Flutter Test + Jest |

## ライセンス

プロプライエタリ — 無断転載・複製禁止
