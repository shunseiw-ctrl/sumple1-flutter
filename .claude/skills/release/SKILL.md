---
name: release
description: iOS実機へのリリースビルド＆インストールを実行する。コード変更後の実機確認に使用。
user-invocable: true
argument-hint: "[確認対象の画面名]"
allowed-tools: "Bash, Read"
---

# iOS 実機リリースビルド＆インストール

## 手順

以下を順番に実行してください:

### 1. 事前チェック
```bash
cd $CLAUDE_PROJECT_DIR
flutter analyze --no-fatal-infos
```
- エラーが0件であることを確認
- エラーがあれば修正してから続行

### 2. リリースビルド
```bash
cd $CLAUDE_PROJECT_DIR
flutter build ios --release
```
- ビルドエラーがあれば修正

### 3. 実機インストール
```bash
xcrun devicectl device install app --device 00008140-0005245E2EFA801C build/ios/iphoneos/Runner.app
```

### 4. 確認事項の報告
ユーザーに以下を報告:
- ビルド結果（成功/失敗）
- インストール結果
- 実機で確認すべき画面・操作手順（$ARGUMENTS があればそれに基づいて具体的に）

## 注意事項
- debugビルドはホーム画面から起動不可。必ずreleaseビルドを使う
- デバイスUDID: `00008140-0005245E2EFA801C`
