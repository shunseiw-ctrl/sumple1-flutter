---
name: code-review
description: コード変更のレビューを実行する。新機能実装、バグ修正、リファクタリング後に使用。
user-invocable: true
argument-hint: "[レビュー対象のファイルパスまたは機能名]"
context: fork
agent: code-reviewer
---

# コードレビュー

## レビュー対象
$ARGUMENTS

## チェックリスト

### 1. 正確性
- ロジックにバグがないか
- エッジケースが処理されているか
- null安全性は確保されているか

### 2. アーキテクチャ準拠
- レイヤー構成: pages/presentation → core/providers → data/repositories → Firebase
- Riverpod パターンに従っているか
- go_router のルーティング規約に合っているか

### 3. コーディング規約
- i18n: UI文字列がすべて `AppLocalizations` 経由か（ハードコード禁止）
- テーマ: `Theme.of(context)` 使用、ハードコード色禁止
- ダークモード対応されているか
- コメントは日本語か

### 4. テスト
- 新機能にユニットテストが追加されているか
- テスト命名: `テスト対象_条件_期待結果`
- mocktail / fake_cloud_firestore / firebase_auth_mocks 使用

### 5. セキュリティ
- Firebase操作にtry-catchがあるか
- ユーザー入力のバリデーションがあるか
- 機密情報がハードコードされていないか

### 6. パフォーマンス
- 不要なリビルドがないか（const活用）
- Firestoreクエリに適切なlimit/paginationがあるか
- 画像にAppCachedImageを使っているか

## 出力形式
問題をカテゴリ別に整理し、重要度順に報告してください。
修正が必要な箇所は具体的なファイルパスと行番号を含めてください。
