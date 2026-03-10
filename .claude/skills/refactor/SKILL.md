---
name: refactor
description: コードのリファクタリングを安全に実行する。重複削除、構造改善、パフォーマンス最適化に使用。
user-invocable: true
argument-hint: "[リファクタリング対象のファイルまたはモジュール]"
---

# リファクタリングプレイブック

## 対象
$ARGUMENTS

## 手順

### Phase 1: 分析
1. 対象コードを読み、現在の構造を理解
2. 関連するテストを特定
3. 依存関係を確認（このコードを使っている箇所）
4. リファクタリングの方針を決定

### Phase 2: テストの確認
```bash
cd $CLAUDE_PROJECT_DIR
flutter test
```
- リファクタリング前にテストが全PASSすることを確認
- テストがない場合は先にテストを追加

### Phase 3: リファクタリング実行
- 小さなステップで段階的に変更
- 各ステップ後に `flutter analyze` でエラーチェック
- 機能の変更は行わない（振る舞いを保持）

### Phase 4: 検証
```bash
flutter analyze
flutter test
```
- 全テストPASS、analyzeエラー0件を確認

## リファクタリングパターン

### 推奨パターン
- **重複コード**: 共通部分を `lib/core/widgets/` または `lib/core/utils/` に抽出
- **巨大ファイル**: 300行超は分割を検討
- **直接Firebase参照**: リポジトリパターン経由に統一
- **ハードコード値**: `lib/core/constants/` に定数化
- **レガシーwidgets/**: `lib/core/widgets/` に移動

### 禁止事項
- 機能の追加・変更（リファクタリングに集中）
- `lib/widgets/` への新規ファイル追加（レガシー）
- テストなしでの大規模変更
