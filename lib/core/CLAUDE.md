# core/ — アプリ共通基盤

アプリ全体で共有される基盤コード。全ページ・機能がここに依存する。

## 重要な注意事項

### providers/
- **Riverpod パターン**: `StateNotifierProvider` + `StateNotifier<AsyncValue<T>>` が基本
- **命名規約**: `xxxProvider` / `xxxNotifier`
- **Admin系プロバイダー**: `admin_*_provider.dart` が8ファイルある。全て `limit(100)` がハードコードされている（将来要修正）
- **auth_provider.dart**: 認証状態の中核。変更時は AuthGate パターンへの影響を必ず確認
- **firebase_providers.dart**: FirebaseAuth/Firestore のインスタンス提供。DI の起点

### router/
- **go_router**: ShellRoute でボトムナビゲーション構成
- **Deep Linking**: `app_links` パッケージ対応
- **ガード**: 認証が必要なルートは redirect で制御
- ルート追加時は `go_router` の宣言的ルーティングに従うこと

### widgets/
- **新規ウィジェットはここに追加** (`lib/widgets/` はレガシー、追加禁止)
- 再利用性を考慮: 3箇所以上で使うならここに抽出
- `SectionTitle`, `WhiteCard` など共通UIコンポーネント

### config/
- **FeatureFlags**: Stripe決済は現在フラグで非表示化中
- Firebase 環境設定（staging/production）

### constants/
- バリデーション定数、UIサイズ定数など集約
- マジックナンバー禁止 → ここに定数化

## 変更時の影響範囲
core/ の変更はアプリ全体に波及する。変更後は必ず `flutter test` を全実行すること。
