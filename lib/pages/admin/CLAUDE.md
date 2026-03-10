# pages/admin/ — 管理者パネル

ALBAWORKの管理者向けダッシュボード。最も複雑なモジュール。

## アーキテクチャ

### 5タブ構成
管理者パネルは5つのタブで構成されている。各タブは独立したプロバイダーを持つ。

### ストリーム管理
- **rxdart** を使用したリアルタイムストリーム
- `onErrorReturn` でストリームエラーを安全にハンドル（Phase 22 で導入）
- `combineLatest` で複数ストリームを統合

### プロバイダー構成
- `admin_jobs_provider.dart` — 案件一覧管理
- `admin_applicants_provider.dart` — 応募者管理
- `admin_approval_provider.dart` — 承認ワークフロー
- `admin_inspections_provider.dart` — 検査管理
- `admin_work_reports_provider.dart` — 日報管理
- `admin_active_workers_provider.dart` — 稼働中作業員
- `admin_kpi_provider.dart` — KPIダッシュボード
- `admin_pending_counts_provider.dart` — 未処理件数バッジ

## 既知の技術的負債

### limit(100) ハードコーディング
全 Admin プロバイダーで `limit(100)` + `hasMore: false` がハードコードされている。
データ増加時にページネーション実装が必要。10箇所以上に散在。

### collectionGroup クエリ
`firestore.rules` にワイルドカードルール（`match /{path=**}/subcollection/{doc}`）が必要。
ルールなしだと権限エラーになる。

## 変更時の注意
- Admin系の変更は `flutter test test/unit/providers/admin_*` で個別テスト推奨
- KPI計算ロジックの変更は数値の整合性を必ず検証
- ストリーム変更時は `rxdart` のエラーハンドリング（`onErrorReturn`）を忘れないこと
