# sumple1 — ALBALIZE 内装工事マッチングアプリ

建設・内装業界向けの案件マッチングアプリ。株式会社ALBALIZEが保有する内装工事案件と、
熟練の内装職人をつなぐプラットフォーム。ゲスト閲覧 → 認証 → 応募の段階的フロー。
将来的にはALBALIZE・職人・管理会社の三者をつなぐアプリに進化予定。

開発体制: 開発者1名 + Claude Code

## ワークフロー原則

**必ず守ること:**
- いきなりコードを書かない。まずプラン（Plan Mode）で設計してから実装に入る
- 作業効率化のため並列（subagent等）で作業する
- 全ての推論・思考プロセスは英語で行い、ユーザーへの回答・提案は日本語で行う
- 不確かな情報を「もっともらしく」回答しない（ハルシネーション厳禁）。不明な場合は「不明」と明記する
- 公式ドキュメント・一次ソースをベースに情報を精査する
- 使用技術は常に最新の安定版（Stable）と公式推奨ベストプラクティスを優先
- 仕様変更・新機能追加のたびに README.md を更新する
- 大きな変更（新機能追加、リファクタリング、Phase完了時など）のたびに `/simplify` でコードレビューを実行し、重複・品質・効率の問題を修正する

## 品質パイプライン（実装後に必ず実行）

コード変更を伴う実装が完了したら、以下のサブエージェントパイプラインを **毎回** 実行する:

### Step 1: プラットフォームビルド検証（並列）
ios-developer と android-developer を **同時に** 起動し、各プラットフォームでビルドが通るか確認:
- `ios-developer`: `flutter build ios --no-codesign` の成功確認 + ios/ ディレクトリの変更があれば妥当性チェック
- `android-developer`: `flutter build apk --debug` の成功確認 + android/ ディレクトリの変更があれば妥当性チェック

### Step 2: E2Eテスト
e2e-tester を起動し、Maestro視覚テストを実行:
- `bash scripts/e2e_test.sh --no-shutdown`（ビルド済みなら `--skip-build` 追加）
- スクリーンショットで表示崩れ・リグレッションを確認

### Step 3: コードレビュー
code-reviewer を起動し、コード品質をチェック

### Step 4: UI/UXレビュー
general-purpose エージェントを起動し、`.claude/agents/ui-ux-reviewer.md` の指示に従ってUI/UXレビューを実行させる。
プロンプト例: 「.claude/agents/ui-ux-reviewer.md を読み、その指示に従って今回の変更のUI/UXレビューを実行してください。」

**注意:**
- Step 1 の2つは並列実行（1つのメッセージで同時にAgent呼び出し）
- Step 2〜4 は順次実行（前のステップの結果を踏まえて次へ）
- 各ステップで問題が見つかった場合は修正してから次へ進む
- テストコードのみの変更（test: タスク）では Step 2 はスキップ可
- ui-ux-reviewer はカスタムエージェントのため `general-purpose` 型で呼び出すこと

## Git 運用（GitHub Flow）

### ブランチ戦略
```
main（本番）
  └─ feature/issue-123-機能名   # 新機能
  └─ fix/issue-456-バグ概要     # バグ修正
  └─ chore/issue-789-作業内容   # 保守・リファクタ
  └─ docs/issue-012-ドキュメント # ドキュメント更新
```
- main から feature ブランチを作成 → 作業 → PR → main にマージ
- main への直接コミットは禁止

### コミットメッセージ
日本語で記述。英語プレフィックス + Issue番号を必ず含める:
```
feat: #123 ゲスト向け案件検索画面を追加
fix: #456 ダークモードで文字色が見えない問題を修正
docs: #789 README.mdにデプロイ手順を追記
refactor: #101 認証フローのプロバイダー構成を整理
test: #202 QRチェックイン機能のユニットテストを追加
chore: #303 Flutter SDKを3.8.1にアップデート
```

### Issue 管理
- すべてのタスク・機能開発・バグ修正は GitHub Issues で管理
- 実装前に該当 Issue を確認し、完了時に Issue コメントに結果を記録

## ビルド・テスト・デプロイ

```bash
# Flutter
flutter run                          # アプリ起動
flutter test                         # ユニットテスト全体
flutter test test/path_to_test.dart  # 単一テスト（推奨）
flutter analyze                      # 静的解析
flutter build web                    # Web版ビルド
flutter build apk                    # Android APK
flutter build ios                    # iOS ビルド

# Cloud Functions（functions/ ディレクトリ）
cd functions && npm test             # Jest テスト
cd functions && npm run lint         # ESLint
firebase deploy --only functions     # Functions デプロイ

# Firebase ルール
firebase deploy --only firestore:rules
firebase deploy --only storage

# l10n（ローカライゼーション生成）
flutter gen-l10n
```

## ディレクトリ構成

```
lib/
├── core/               # アプリ共通基盤
│   ├── config/         # Firebase設定、環境変数、FeatureFlags
│   ├── constants/      # 定数定義
│   ├── enums/          # ユーザー権限など列挙型
│   ├── extensions/     # Dart拡張メソッド
│   ├── providers/      # Riverpod グローバルプロバイダー
│   ├── router/         # go_router ルーティング定義
│   ├── services/       # コアサービス（シェア機能等）
│   ├── utils/          # ユーティリティ関数
│   └── widgets/        # 汎用ウィジェット（新規はここ）
├── data/
│   ├── models/         # データモデル（Firestore ドキュメント対応）
│   └── repositories/   # リポジトリパターン（Firestore CRUD）
├── l10n/               # ARBファイル（日本語・英語）
├── pages/              # 認証済みユーザー向けページ
│   ├── admin/          # 管理者ページ
│   ├── profile/        # プロフィール関連
│   └── work_detail/    # 勤務詳細
├── presentation/
│   ├── pages/guest/    # ゲスト（未認証）向けページ
│   └── widgets/        # presentation 専用ウィジェット
├── services/           # 外部サービス連携
├── widgets/            # ★レガシー（新規追加禁止）
└── main.dart

functions/              # Cloud Functions（Node.js）
├── src/                # 関数実装
├── tests/              # Jest テスト
└── index.js            # エントリーポイント

test/                   # Flutter ユニットテスト
integration_test/       # 統合テスト
.github/workflows/      # GitHub Actions CI/CD
docs/                   # ドキュメント
landing/                # ランディングページ
```

### ファイル配置ルール
- ゲスト向けページ → `lib/presentation/pages/guest/`
- 認証済みページ → `lib/pages/`
- 新規ウィジェット → `lib/core/widgets/` または `lib/presentation/widgets/`
- `lib/widgets/` はレガシー。新規ファイルを追加しない
- Cloud Functions は Node.js。Dart ではない

## アーキテクチャ

### レイヤー構成
pages/presentation → core/providers → data/repositories → Firebase

### 認証フロー（AuthGate パターン）
- 初回起動: GuestHomePage を即表示（オンボーディングなし）
- ゲスト: 案件閲覧・検索・地図検索が可能
- 認証が必要な操作（応募、チャット等）: ログイン画面へ誘導
- 認証方式: Email/Password、電話番号、Apple Sign In

### 状態管理
- flutter_riverpod（ConsumerWidget / ConsumerStatefulWidget）
- グローバルプロバイダー → lib/core/providers/
- ページ固有の状態 → ページ内で定義

### ルーティング
- go_router（lib/core/router/）
- ShellRoute でボトムナビゲーション構成
- Deep Linking 対応（app_links）

## コーディング規約

### 言語
- コード内コメント: 日本語
- コミットメッセージ: 日本語（英語プレフィックス付き）
- ARBファイル: 日本語・英語の2言語

### i18n（国際化）
- すべてのUI文字列は `AppLocalizations.of(context)!.keyName` を使用
- ハードコード文字列は禁止
- 新キー追加後は `flutter gen-l10n` を実行

### テーマ
- ダークモード完全対応（ライト/ダーク/システム設定の3択）
- `Theme.of(context)` を使い、ハードコードの色指定禁止
- フォント: google_fonts

### テスト
- モック: mocktail
- Firestore モック: fake_cloud_firestore
- Auth モック: firebase_auth_mocks
- 新機能には必ずユニットテストを追加
- テスト命名: `テスト対象_条件_期待結果`

### モデル
- lib/data/models/ に配置。Firestore ドキュメントと 1:1 対応
- fromMap / toMap パターンで変換

### エラーハンドリング
- try-catch で Firebase 操作をラップ
- エラーメッセージは l10n 経由で表示
- Crashlytics に非致命的エラーを送信

## 主要機能

| 機能 | 関連ファイル | 技術 |
|------|-------------|------|
| QR出退勤 | qr_checkin_page, shift_qr_page | mobile_scanner + geolocator |
| Stripe決済 | stripe_onboarding_page, payment_detail | webview_flutter + Cloud Functions |
| 地図検索 | map_search_page | google_maps_flutter |
| チャット | chat_room_page, messages_page | Firestore リアルタイム |
| eKYC本人確認 | identity_verification_page | Firebase Storage |
| 紹介コード | referral_page | share_plus |
| プッシュ通知 | — | firebase_messaging + flutter_local_notifications |

## 環境設定

### Firebase 環境切替
- `firebase use staging` / `firebase use production`
- .firebaserc で管理

### 機密ファイル（git 管理外）
google-services.json, GoogleService-Info.plist, .env（Stripe キー等）

### FeatureFlags
- lib/core/config/ で定義
- Stripe 決済は現在フラグで非表示化中

## CI/CD
- GitHub Actions（.github/workflows/）
- テスト → ビルド → デプロイの自動化
