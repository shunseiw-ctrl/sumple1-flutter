#!/usr/bin/env bash
#
# issue_watcher.sh — GitHub Issue監視 → TODO.md追記 → auto_dev.py呼び出し
#
# label:auto のIssueを監視し、TODO.mdに追記する
#

set -euo pipefail

# ─── 定数 ───────────────────────────────────────────────
PROJECT_DIR="/Users/albalize/Desktop/sumple1-flutter-main"
TODO_FILE="$PROJECT_DIR/TODO.md"
SCRIPT_DIR="$PROJECT_DIR/scripts"
LOG_DIR="$PROJECT_DIR/logs"
LOCK_FILE="/tmp/albawork_auto_dev.lock"

export PATH="/opt/homebrew/bin:/Users/albalize/flutter/bin:$PATH"

# ─── ユーティリティ ───────────────────────────────────
timestamp() {
  date '+%Y-%m-%d %H:%M'
}

log() {
  mkdir -p "$LOG_DIR"
  echo "[$(timestamp)] [issue_watcher] $*" | tee -a "$LOG_DIR/issue_watcher.log"
}

# [Tier1-1] TODO.mdへの追記もtmpfile方式で安全に行う
add_to_pending() {
  local new_line="$1"
  local tmpfile
  tmpfile=$(mktemp)
  local inserted=0
  while IFS= read -r line; do
    echo "$line"
    if [[ "$line" == "## PENDING" && $inserted -eq 0 ]]; then
      echo "$new_line"
      inserted=1
    fi
  done < "$TODO_FILE" > "$tmpfile"
  mv "$tmpfile" "$TODO_FILE"
}

# ─── メイン処理 ───────────────────────────────────────
main() {
  log "=== Issue監視開始 ==="

  cd "$PROJECT_DIR"

  # リポジトリ情報取得
  local repo
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
  if [[ -z "$repo" ]]; then
    log "ERROR: GitHubリポジトリが特定できません"
    exit 1
  fi

  # label:auto のオープンIssueを取得
  local issues
  issues=$(gh issue list --label "auto" --state open --json number,title --repo "$repo" 2>/dev/null || echo "[]")

  if [[ "$issues" == "[]" || -z "$issues" ]]; then
    log "autoラベルのIssueなし"
    exit 0
  fi

  # [Tier1-5] サブシェル問題修正：プロセス置換でwhile readを実行
  # パイプ（|）ではサブシェルが作られ変数が親に伝播しないため、
  # <<< ヒアストリング + 一時ファイル方式に変更
  local new_tasks=0
  local issue_lines
  issue_lines=$(echo "$issues" | jq -c '.[]')

  while IFS= read -r issue; do
    [[ -z "$issue" ]] && continue

    local issue_num
    local issue_title
    issue_num=$(echo "$issue" | jq -r '.number')
    issue_title=$(echo "$issue" | jq -r '.title')

    # TODO.mdに既に存在するかチェック
    if grep -q "#${issue_num} " "$TODO_FILE" 2>/dev/null; then
      log "スキップ: #${issue_num} (既にTODO.mdに存在)"
      continue
    fi

    # PENDINGセクションに追記（tmpfile方式）
    log "新規タスク追加: #${issue_num} ${issue_title}"
    add_to_pending "- [ ] #${issue_num} ${issue_title}"
    new_tasks=$((new_tasks + 1))
  done <<< "$issue_lines"

  log "新規タスク: ${new_tasks}件追加"

  # 新規タスクがあり、auto_dev.pyが実行中でなければ起動
  if [[ $new_tasks -gt 0 && ! -f "$LOCK_FILE" ]]; then
    log "auto_dev.py を起動します"
    nohup python3 "$SCRIPT_DIR/auto_dev.py" >> "$LOG_DIR/auto_dev_triggered.log" 2>&1 &
    log "auto_dev.py を起動しました (PID: $!)"
  elif [[ -f "$LOCK_FILE" ]]; then
    log "auto_dev.py は既に実行中（スキップ）"
  fi

  log "=== Issue監視完了 ==="
}

main "$@"
