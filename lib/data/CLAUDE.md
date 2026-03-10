# data/ — データ層

Firestore ドキュメントとアプリ内データの橋渡し。

## models/
- Firestore ドキュメントと 1:1 対応
- **必須メソッド**: `fromMap(Map<String, dynamic>)` / `toMap()` / `fromFirestore(DocumentSnapshot)`
- **型変換の注意**: Firestore の数値は `num` で返る場合がある → `(value as num?)?.toInt()` を使うこと（`as int` は危険）
- **JobModel**: `fromMap` / `fromFirestore` が型バリエーションを吸収する設計。参考にすること
- 新モデル追加時は対応するユニットテストも必須

## repositories/
- **CRUD パターン**: `add`, `update`, `delete`, `getById`, `getAll` が基本
- **エラーハンドリング**: 全 Firebase 操作を `try-catch` でラップ
- **ページネーション**: `startAfterDocument` + `limit` パターン
- **collectionGroup クエリ**: 使用時は `firestore.rules` にワイルドカードルール（`{path=**}`）が必要
- Firestore の直接参照は避け、必ずリポジトリ経由にする

## テスト
- `fake_cloud_firestore` でモック
- `TestFixtures` クラス（`test/helpers/test_fixtures.dart`）でモデルファクトリを提供
- テストファイルは `test/unit/models/` と `test/unit/repositories/` に配置
