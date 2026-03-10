#!/bin/bash
# PreToolUse hook: 保護対象ファイルの編集をブロック
# exit 2 = ブロック（stderrがClaudeへのフィードバック）
# exit 0 = 許可

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 保護対象ファイル（直接編集禁止）
PROTECTED_FILES=(
  "google-services.json"
  "GoogleService-Info.plist"
  ".env"
  "ios/Runner.xcodeproj/project.pbxproj"
)

for pattern in "${PROTECTED_FILES[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "BLOCKED: $FILE_PATH は保護対象ファイルです。このファイルを編集する必要がある場合、ユーザーに確認してください。" >&2
    exit 2
  fi
done

# 注意が必要なファイル（警告のみ、ブロックしない）
SENSITIVE_FILES=(
  "firestore.rules"
  "firestore.indexes.json"
  "firebase.json"
  "pubspec.yaml"
  "analysis_options.yaml"
)

for pattern in "${SENSITIVE_FILES[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "WARNING: $FILE_PATH はインフラ設定ファイルです。変更内容がプロジェクト全体に影響します。慎重に編集してください。"
    exit 0
  fi
done

exit 0
