#!/bin/bash
# PostToolUse hook: .dartファイル編集後にdart analyzeを自動実行
# stdoutの内容がClaudeへのフィードバックとして送られる

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# .dartファイル以外はスキップ
if [[ "$FILE_PATH" != *.dart ]]; then
  exit 0
fi

# テストファイルはスキップ（テスト編集中の高速化）
if [[ "$FILE_PATH" == */test/* ]]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

# 該当ファイルのみ解析（プロジェクト全体より高速）
RESULT=$(dart analyze "$FILE_PATH" 2>&1)

# エラーまたは警告がある場合のみ出力
if echo "$RESULT" | grep -qE "error •|warning •"; then
  ERRORS=$(echo "$RESULT" | grep -c "error •" || true)
  WARNINGS=$(echo "$RESULT" | grep -c "warning •" || true)
  echo "dart analyze: ${ERRORS} errors, ${WARNINGS} warnings in $(basename "$FILE_PATH")"
  echo "$RESULT" | grep -E "error •|warning •" | head -10
fi

exit 0
