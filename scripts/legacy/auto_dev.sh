#!/usr/bin/env bash
#
# auto_dev.sh — ALBAWORK自律開発オーケストレーター
# OpenClawの「Planner-Executor」モデルをbashで再現
#
# 使い方:
#   bash scripts/auto_dev.sh              # PENDINGの最上位タスク1件を実行
#   bash scripts/auto_dev.sh --all 3      # 成功3件まで順次実行
#

set -euo pipefail

# ─── 定数 ───────────────────────────────────────────────
PROJECT_DIR="/Users/albalize/Desktop/sumple1-flutter-main"
TODO_FILE="$PROJECT_DIR/TODO.md"
REPORT_FILE="$PROJECT_DIR/REPORT.md"
LOCK_FILE="/tmp/albawork_auto_dev.lock"
# [A] /tmpではなくプロジェクト内に保存（macOS再起動で消えない）
FAIL_COUNT_DIR="$PROJECT_DIR/.auto_dev/fail_counts"
LOG_DIR="$PROJECT_DIR/logs"
PROMPT_DIR="$PROJECT_DIR/scripts/prompts"
LOG_RETENTION_DAYS=7
REPORT_MAX_ENTRIES=50  # [I] REPORT.mdの最大エントリ数
MAX_RETRIES=2
MAX_FAIL_TOTAL=3
TASK_TIMEOUT=1800  # 30分
MAX_TURNS=30
MAX_TASKS=1  # [J] 「成功N件」でカウント

# [F] LINE Messaging API（空なら無効）
LINE_CHANNEL_TOKEN="${LINE_CHANNEL_TOKEN:-}"
LINE_USER_ID="${LINE_USER_ID:-}"

# Slack webhook（空なら無効）
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

# PATH設定（launchd環境用）
export PATH="/opt/homebrew/bin:/Users/albalize/flutter/bin:$PATH"

# ネストされたClaudeセッション防止を回避（launchdやcronから呼ばれる場合用）
unset CLAUDECODE 2>/dev/null || true

# ─── 引数処理 ─────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      MAX_TASKS="${2:-3}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# ─── ユーティリティ ───────────────────────────────────
timestamp() {
  date '+%Y-%m-%d %H:%M'
}

log() {
  echo "[$(timestamp)] $*" | tee -a "$LOG_DIR/auto_dev.log"
}

notify() {
  local message="$1"
  # macOS通知
  osascript -e "display notification \"$message\" with title \"ALBAWORK Auto Dev\"" 2>/dev/null || true

  # [F] LINE Messaging API push送信
  if [[ -n "$LINE_CHANNEL_TOKEN" && -n "$LINE_USER_ID" ]]; then
    curl -s -X POST https://api.line.me/v2/bot/message/push \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $LINE_CHANNEL_TOKEN" \
      -d "{\"to\":\"$LINE_USER_ID\",\"messages\":[{\"type\":\"text\",\"text\":\"[ALBAWORK] $message\"}]}" \
      >/dev/null 2>&1 || true
  fi

  # Slack webhook
  if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
    curl -s -X POST "$SLACK_WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{\"text\":\"[ALBAWORK] $message\"}" \
      >/dev/null 2>&1 || true
  fi
}

cleanup() {
  rm -f "$LOCK_FILE"
  log "ロックファイル解放"
}

# ログローテーション
rotate_logs() {
  if [[ -d "$LOG_DIR" ]]; then
    find "$LOG_DIR" -name "*.log" -mtime +${LOG_RETENTION_DAYS} -delete 2>/dev/null || true
    log "ログローテーション完了（${LOG_RETENTION_DAYS}日以上前のログを削除）"
  fi
}

# [I] REPORT.md肥大化対策（最新N件のみ保持）
truncate_report() {
  if [[ ! -f "$REPORT_FILE" ]]; then return; fi
  local entry_count
  entry_count=$(grep -c '^## [0-9]' "$REPORT_FILE" 2>/dev/null || echo "0")
  if [[ "$entry_count" -le "$REPORT_MAX_ENTRIES" ]]; then return; fi

  log "REPORT.md: ${entry_count}件 → ${REPORT_MAX_ENTRIES}件にトランケート"
  local tmpfile
  tmpfile=$(mktemp)
  local current_entry=0
  local keep=1
  while IFS= read -r line; do
    if [[ "$line" == "## "* && "$line" =~ ^##\ [0-9] ]]; then
      current_entry=$((current_entry + 1))
      if [[ $current_entry -gt $REPORT_MAX_ENTRIES ]]; then
        keep=0
      fi
    fi
    if [[ $keep -eq 1 ]]; then
      echo "$line"
    fi
  done < "$REPORT_FILE" > "$tmpfile"
  mv "$tmpfile" "$REPORT_FILE"
}

# [H] gh auth事前チェック
check_gh_auth() {
  if ! gh auth status &>/dev/null; then
    log "FATAL: GitHub認証が無効です。gh auth login を実行してください"
    notify "FATAL: GitHub認証切れ。自律開発を停止しました"
    exit 1
  fi
}

# ─── 失敗カウント管理 ────────────────────────────────
get_fail_count() {
  local issue_num="$1"
  local count_file="$FAIL_COUNT_DIR/issue_${issue_num}"
  if [[ -f "$count_file" ]]; then
    cat "$count_file"
  else
    echo "0"
  fi
}

increment_fail_count() {
  local issue_num="$1"
  mkdir -p "$FAIL_COUNT_DIR"
  local count_file="$FAIL_COUNT_DIR/issue_${issue_num}"
  local current
  current=$(get_fail_count "$issue_num")
  echo $((current + 1)) > "$count_file"
}

reset_fail_count() {
  local issue_num="$1"
  rm -f "$FAIL_COUNT_DIR/issue_${issue_num}" 2>/dev/null || true
}

# ─── ロック管理 ────────────────────────────────────────
acquire_lock() {
  if [[ -f "$LOCK_FILE" ]]; then
    local lock_pid
    lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
      log "ERROR: 既に実行中 (PID: $lock_pid)"
      exit 1
    else
      log "WARN: 古いロックファイルを削除"
      rm -f "$LOCK_FILE"
    fi
  fi
  echo $$ > "$LOCK_FILE"
  trap cleanup EXIT
  log "ロック取得 (PID: $$)"
}

# ─── TODO.md操作（tmpfile全書き換え方式：特殊文字安全） ──
# [G] 全セクション検出に ## FAILED を含める

get_next_task() {
  local in_pending=0
  while IFS= read -r line; do
    if [[ "$line" == "## PENDING" ]]; then
      in_pending=1
      continue
    fi
    if [[ $in_pending -eq 1 && "$line" == "## "* ]]; then
      break
    fi
    if [[ $in_pending -eq 1 && "$line" == "- [ ] "* ]]; then
      echo "$line"
      return
    fi
  done < "$TODO_FILE"
}

extract_issue_number() {
  echo "$1" | grep -oE '#[0-9]+' | head -1 | tr -d '#'
}

extract_task_title() {
  echo "$1" | sed 's/^- \[ \] #[0-9]* //'
}

# セクションヘッダーかどうか判定
is_section_header() {
  local line="$1"
  [[ "$line" == "## PENDING" || "$line" == "## IN_PROGRESS" || "$line" == "## DONE" || "$line" == "## FAILED" ]]
}

move_to_in_progress() {
  local task_line="$1"
  local session_id="$2"
  local tmpfile
  tmpfile=$(mktemp)
  local done_line
  done_line="- [x] $(echo "$task_line" | sed 's/^- \[ \] //') (session: $session_id)"

  local current_section=""
  local task_moved=0
  while IFS= read -r line; do
    if is_section_header "$line"; then
      current_section="$line"
    fi
    if [[ "$current_section" == "## PENDING" && "$line" == "$task_line" && $task_moved -eq 0 ]]; then
      task_moved=1
      continue
    fi
    echo "$line"
    if [[ "$line" == "## IN_PROGRESS" ]]; then
      echo "$done_line"
    fi
  done < "$TODO_FILE" > "$tmpfile"
  mv "$tmpfile" "$TODO_FILE"
}

move_to_done() {
  local issue_num="$1"
  local pr_number="$2"
  local tmpfile
  tmpfile=$(mktemp)
  local current_section=""
  local target_line=""
  local done_entry=""

  while IFS= read -r line; do
    if [[ "$line" == "## IN_PROGRESS" ]]; then
      current_section="IN_PROGRESS"
      continue
    fi
    if [[ "$line" == "## "* ]]; then
      current_section=""
      continue
    fi
    if [[ "$current_section" == "IN_PROGRESS" && "$line" == *"#${issue_num} "* ]]; then
      target_line="$line"
      done_entry=$(echo "$line" | sed 's/ (session: [^)]*)//')
      done_entry="$done_entry (PR #$pr_number)"
      break
    fi
  done < "$TODO_FILE"

  if [[ -z "$target_line" ]]; then return; fi

  current_section=""
  local line_removed=0
  while IFS= read -r line; do
    if is_section_header "$line"; then
      current_section="$line"
    fi
    if [[ "$current_section" == "## IN_PROGRESS" && "$line" == "$target_line" && $line_removed -eq 0 ]]; then
      line_removed=1
      continue
    fi
    echo "$line"
    if [[ "$line" == "## DONE" ]]; then
      echo "$done_entry"
    fi
  done < "$TODO_FILE" > "$tmpfile"
  mv "$tmpfile" "$TODO_FILE"
}

move_back_to_pending() {
  local issue_num="$1"
  local tmpfile
  tmpfile=$(mktemp)
  local current_section=""
  local target_line=""
  local pending_entry=""

  while IFS= read -r line; do
    if [[ "$line" == "## IN_PROGRESS" ]]; then
      current_section="IN_PROGRESS"
      continue
    fi
    if [[ "$line" == "## "* ]]; then
      current_section=""
      continue
    fi
    if [[ "$current_section" == "IN_PROGRESS" && "$line" == *"#${issue_num} "* ]]; then
      target_line="$line"
      pending_entry=$(echo "$line" | sed 's/- \[x\]/- [ ]/' | sed 's/ (session: [^)]*)//')
      break
    fi
  done < "$TODO_FILE"

  if [[ -z "$target_line" ]]; then return; fi

  current_section=""
  local line_removed=0
  while IFS= read -r line; do
    if is_section_header "$line"; then
      current_section="$line"
    fi
    if [[ "$current_section" == "## IN_PROGRESS" && "$line" == "$target_line" && $line_removed -eq 0 ]]; then
      line_removed=1
      continue
    fi
    echo "$line"
    if [[ "$line" == "## PENDING" ]]; then
      echo "$pending_entry"
    fi
  done < "$TODO_FILE" > "$tmpfile"
  mv "$tmpfile" "$TODO_FILE"
}

move_to_failed() {
  local issue_num="$1"
  local reason="$2"
  local tmpfile
  tmpfile=$(mktemp)
  local current_section=""
  local target_line=""

  while IFS= read -r line; do
    if [[ "$line" == "## IN_PROGRESS" ]]; then
      current_section="IN_PROGRESS"
      continue
    fi
    if [[ "$line" == "## "* ]]; then
      current_section=""
      continue
    fi
    if [[ "$current_section" == "IN_PROGRESS" && "$line" == *"#${issue_num} "* ]]; then
      target_line="$line"
      break
    fi
  done < "$TODO_FILE"

  if [[ -z "$target_line" ]]; then return; fi

  local failed_entry
  failed_entry=$(echo "$target_line" | sed 's/ (session: [^)]*)//')
  failed_entry="$failed_entry (FAILED: $reason)"

  current_section=""
  local line_removed=0
  local has_failed_section=0
  if grep -q "^## FAILED" "$TODO_FILE"; then
    has_failed_section=1
  fi

  while IFS= read -r line; do
    if is_section_header "$line"; then
      current_section="$line"
    fi
    if [[ "$current_section" == "## IN_PROGRESS" && "$line" == "$target_line" && $line_removed -eq 0 ]]; then
      line_removed=1
      continue
    fi
    echo "$line"
    if [[ "$line" == "## FAILED" ]]; then
      echo "$failed_entry"
    fi
    if [[ "$line" == "## DONE" && $has_failed_section -eq 0 ]]; then
      echo ""
      echo "## FAILED"
      echo "$failed_entry"
      has_failed_section=1
    fi
  done < "$TODO_FILE" > "$tmpfile"
  mv "$tmpfile" "$TODO_FILE"
}

# ─── REPORT.md操作 ────────────────────────────────────
write_report() {
  local issue_num="$1"
  local task_title="$2"
  local status="$3"
  local changed_files="$4"
  local test_result="$5"
  local pr_number="$6"
  local notes="$7"

  local tmpfile
  tmpfile=$(mktemp)
  {
    echo "# REPORT"
    echo ""
    echo "## $(timestamp) — #${issue_num} ${task_title}"
    echo "- **ステータス**: ${status}"
    echo "- **変更ファイル**: ${changed_files}"
    echo "- **テスト結果**: ${test_result}"
    echo "- **PR**: ${pr_number}"
    echo "- **課題**: ${notes}"
    echo ""
    if [[ -s "$REPORT_FILE" ]]; then
      tail -n +2 "$REPORT_FILE"
    fi
  } > "$tmpfile"
  mv "$tmpfile" "$REPORT_FILE"
}

# ─── メイン実行 ───────────────────────────────────────
execute_task() {
  local task_line="$1"
  local issue_num
  local task_title
  local branch_name
  local session_id
  local retry_count=0

  issue_num=$(extract_issue_number "$task_line")
  task_title=$(extract_task_title "$task_line")
  branch_name="auto/${issue_num}-$(echo "$task_title" | tr ' :' '-' | tr -cd 'a-zA-Z0-9-' | head -c 40)"
  session_id=$(date '+%s' | tail -c 7)

  # 累計失敗カウントチェック
  local total_fails
  total_fails=$(get_fail_count "$issue_num")
  if [[ "$total_fails" -ge $MAX_FAIL_TOTAL ]]; then
    log "SKIP: #${issue_num} は累計${total_fails}回失敗済み → FAILED固定"
    move_to_in_progress "$task_line" "$session_id"
    move_to_failed "$issue_num" "累計${total_fails}回失敗"
    write_report "$issue_num" "$task_title" "FAILED（永久停止）" "-" "-" "-" "累計${total_fails}回失敗で自動停止"
    notify "FAILED: #${issue_num} ${task_title}（累計${total_fails}回失敗）"
    return 1
  fi

  log "タスク開始: #${issue_num} ${task_title} (累計失敗: ${total_fails}/${MAX_FAIL_TOTAL})"
  notify "タスク開始: #${issue_num} ${task_title}"

  # Issueのbodyを取得
  local issue_body=""
  if [[ -n "$issue_num" ]]; then
    issue_body=$(gh issue view "$issue_num" --repo "$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)" --json body -q .body 2>/dev/null || echo "")
  fi

  cd "$PROJECT_DIR"

  # git checkout前にstash
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    log "未コミット変更あり → git stash"
    git stash push -m "auto_dev: before task #${issue_num}" 2>/dev/null || true
  fi

  # feature branch作成
  git checkout main 2>/dev/null
  git pull origin main 2>/dev/null || true
  git checkout -b "$branch_name" 2>/dev/null || git checkout "$branch_name" 2>/dev/null

  # IN_PROGRESSに移動
  move_to_in_progress "$task_line" "$session_id"

  while [[ $retry_count -lt $MAX_RETRIES ]]; do
    log "実行試行 $((retry_count + 1))/$MAX_RETRIES"

    # [D] リトライ時はブランチをクリーンにリセット
    if [[ $retry_count -gt 0 ]]; then
      log "リトライ前: ブランチをmainベースにリセット"
      git reset --hard main 2>/dev/null || true
    fi

    # [B] プロンプト構築（Issue bodyをファイル経由で安全に注入）
    local claude_prompt
    local template_file="$PROMPT_DIR/task_prompt.template"
    local system_prompt_file="$PROMPT_DIR/system_prompt.txt"
    local body_content="${issue_body:-（Issue本文なし。タスクタイトルから判断して実装してください）}"

    if [[ -f "$template_file" ]]; then
      # テンプレートを読み込んで置換（ファイル経由で安全に）
      local prompt_tmpfile
      prompt_tmpfile=$(mktemp)
      while IFS= read -r tpl_line; do
        case "$tpl_line" in
          *"{{ISSUE_NUM}}"*)
            echo "${tpl_line//\{\{ISSUE_NUM\}\}/$issue_num}"
            ;;
          *"{{TASK_TITLE}}"*)
            echo "${tpl_line//\{\{TASK_TITLE\}\}/$task_title}"
            ;;
          *"{{ISSUE_BODY}}"*)
            echo "$body_content"
            ;;
          *)
            echo "$tpl_line"
            ;;
        esac
      done < "$template_file" > "$prompt_tmpfile"
      claude_prompt=$(cat "$prompt_tmpfile")
      rm -f "$prompt_tmpfile"
    else
      claude_prompt="以下のタスクを実装してください。
#${issue_num} ${task_title}
${body_content}"
    fi

    local claude_output
    local claude_exit_code=0

    # claude実行コマンド構築
    local claude_args=()
    claude_args+=(-p "$claude_prompt")
    claude_args+=(--allowedTools "Read,Grep,Glob,Edit,Write,Bash(flutter *),Bash(dart *),Bash(git add*),Bash(git commit*),Bash(git status*),Bash(git diff*),Bash(git log*),Bash(ls*),Bash(mkdir*),Bash(cat*)")
    claude_args+=(--max-turns "$MAX_TURNS")
    claude_args+=(--output-format text)
    if [[ -f "$system_prompt_file" ]]; then
      claude_args+=(--append-system-prompt "$(cat "$system_prompt_file")")
    fi

    # タイムアウト付きでclaude実行
    local claude_pid
    local output_file
    output_file=$(mktemp)
    claude "${claude_args[@]}" > "$output_file" 2>&1 &
    claude_pid=$!

    local elapsed=0
    while kill -0 "$claude_pid" 2>/dev/null; do
      sleep 5
      elapsed=$((elapsed + 5))
      if [[ $elapsed -ge $TASK_TIMEOUT ]]; then
        log "WARN: タイムアウト (${TASK_TIMEOUT}秒) → claude (PID: $claude_pid) を終了"
        kill "$claude_pid" 2>/dev/null || true
        sleep 2
        kill -9 "$claude_pid" 2>/dev/null || true
        claude_exit_code=124
        break
      fi
    done

    if [[ $claude_exit_code -ne 124 ]]; then
      wait "$claude_pid" || claude_exit_code=$?
    fi

    claude_output=$(cat "$output_file")
    rm -f "$output_file"

    log "Claude終了コード: $claude_exit_code"

    # 「要確認」チェック
    if echo "$claude_output" | grep -q "要確認:"; then
      local concern
      concern=$(echo "$claude_output" | grep "要確認:" | head -3)
      log "要確認事項あり: $concern"
      write_report "$issue_num" "$task_title" "要確認" "-" "-" "-" "$concern"
      increment_fail_count "$issue_num"
      move_back_to_pending "$issue_num"
      notify "要確認: #${issue_num} ${task_title}"
      return 1
    fi

    if [[ $claude_exit_code -ne 0 ]]; then
      log "ERROR: Claude実行失敗 (exit: $claude_exit_code)"
      retry_count=$((retry_count + 1))
      if [[ $retry_count -lt $MAX_RETRIES ]]; then
        log "リトライします..."
        sleep 10
        continue
      fi
      write_report "$issue_num" "$task_title" "失敗" "-" "-" "-" "Claude実行エラー (exit: $claude_exit_code)"
      increment_fail_count "$issue_num"
      move_back_to_pending "$issue_num"
      notify "失敗: #${issue_num} ${task_title}"
      return 1
    fi

    # コミット有無チェック
    local commit_count
    commit_count=$(git log main.."$branch_name" --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$commit_count" -eq 0 ]]; then
      log "WARN: コミットなし"
      retry_count=$((retry_count + 1))
      if [[ $retry_count -lt $MAX_RETRIES ]]; then
        log "リトライします..."
        sleep 10
        continue
      fi
      write_report "$issue_num" "$task_title" "失敗" "0件" "-" "-" "コミットなし"
      increment_fail_count "$issue_num"
      move_back_to_pending "$issue_num"
      notify "失敗: #${issue_num} コミットなし"
      return 1
    fi

    # ─── 検証フェーズ ───
    log "検証開始: flutter analyze"
    local analyze_exit=0
    local analyze_result
    analyze_result=$(cd "$PROJECT_DIR" && flutter analyze 2>&1) || analyze_exit=$?

    if [[ $analyze_exit -ne 0 ]]; then
      local analyze_summary
      analyze_summary=$(echo "$analyze_result" | grep -E '(error|warning)' | tail -3)
      log "ERROR: flutter analyze 失敗 (exit: $analyze_exit): $analyze_summary"
      retry_count=$((retry_count + 1))
      if [[ $retry_count -lt $MAX_RETRIES ]]; then
        log "リトライします..."
        continue
      fi
      write_report "$issue_num" "$task_title" "失敗" "-" "analyze失敗" "-" "$analyze_summary"
      increment_fail_count "$issue_num"
      move_back_to_pending "$issue_num"
      notify "失敗: #${issue_num} analyze エラー"
      return 1
    fi
    log "flutter analyze: OK"

    log "検証開始: flutter test"
    local test_exit=0
    local test_result
    test_result=$(cd "$PROJECT_DIR" && flutter test 2>&1) || test_exit=$?
    local test_pass
    test_pass=$(echo "$test_result" | grep -oE 'All [0-9]+ tests passed' || echo "")

    if [[ $test_exit -ne 0 || -z "$test_pass" ]]; then
      local test_failures
      test_failures=$(echo "$test_result" | tail -5)
      log "ERROR: flutter test 失敗 (exit: $test_exit): $test_failures"
      retry_count=$((retry_count + 1))
      if [[ $retry_count -lt $MAX_RETRIES ]]; then
        log "リトライします..."
        continue
      fi
      write_report "$issue_num" "$task_title" "失敗" "-" "test失敗" "-" "テスト失敗"
      increment_fail_count "$issue_num"
      move_back_to_pending "$issue_num"
      notify "失敗: #${issue_num} テスト失敗"
      return 1
    fi

    # ─── 成功：PR作成 ───
    log "検証成功: $test_pass"

    local changed_files_count
    changed_files_count=$(git diff --stat main..."$branch_name" 2>/dev/null | tail -1 || echo "不明")

    # Claude出力サマリー（PR body用）
    local claude_summary
    claude_summary=$(echo "$claude_output" | tail -200 | head -c 4000)

    # [E] git push失敗検出
    log "git push開始"
    local push_exit=0
    git push -u origin "$branch_name" 2>&1 || push_exit=$?

    if [[ $push_exit -ne 0 ]]; then
      log "ERROR: git push 失敗 (exit: $push_exit)。ローカルブランチは保持します"
      write_report "$issue_num" "$task_title" "失敗" "$changed_files_count" "$test_pass" "-" "git push失敗 (exit: $push_exit)"
      increment_fail_count "$issue_num"
      move_back_to_pending "$issue_num"
      notify "失敗: #${issue_num} git push失敗（ネットワーク確認要）"
      git checkout main 2>/dev/null
      return 1
    fi

    # [C] HEREDOC区切りをランダム化（Claude出力にEOFが含まれても安全）
    local heredoc_delim="AUTODEV_PR_$(date +%s)"

    local pr_url
    pr_url=$(gh pr create \
      --title "#${issue_num} ${task_title}" \
      --body "$(cat <<${heredoc_delim}
## Summary
- Auto-generated by auto_dev.sh
- Task: #${issue_num} ${task_title}

Closes #${issue_num}

## Verification
- flutter analyze: 0 errors
- flutter test: ${test_pass}

## Changes
${changed_files_count}

## Claude Output (auto-generated)
<details>
<summary>Claude実行ログ（クリックで展開）</summary>

\`\`\`
${claude_summary}
\`\`\`

</details>

---
Generated by ALBAWORK Auto Dev System
${heredoc_delim}
)" \
      --base main \
      --head "$branch_name" 2>&1) || true

    local pr_number
    pr_number=$(echo "$pr_url" | grep -oE '[0-9]+$' || echo "unknown")

    log "PR作成: $pr_url"

    move_to_done "$issue_num" "$pr_number"
    write_report "$issue_num" "$task_title" "成功" "$changed_files_count" "analyze OK / $test_pass" "#$pr_number" "なし"
    reset_fail_count "$issue_num"

    notify "成功: #${issue_num} ${task_title} → PR #${pr_number}"
    log "タスク完了: #${issue_num} → PR #${pr_number}"

    # mainに戻す
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
      git stash push -m "auto_dev: after task #${issue_num}" 2>/dev/null || true
    fi
    git checkout main 2>/dev/null

    return 0
  done
}

# ─── エントリーポイント ───────────────────────────────
main() {
  mkdir -p "$LOG_DIR" "$FAIL_COUNT_DIR"
  log "=== auto_dev.sh 開始 ==="

  acquire_lock
  check_gh_auth  # [H] gh認証チェック
  rotate_logs
  truncate_report  # [I] REPORT.md肥大化対策

  # [J] 成功カウント方式（失敗はカウントしない）
  local success_count=0
  local attempt_count=0

  while [[ $success_count -lt $MAX_TASKS ]]; do
    local next_task
    next_task=$(get_next_task)

    if [[ -z "$next_task" ]]; then
      log "PENDINGタスクなし。終了します。"
      break
    fi

    attempt_count=$((attempt_count + 1))

    # 無限ループ防止（試行回数が成功目標の3倍を超えたら停止）
    if [[ $attempt_count -gt $((MAX_TASKS * 3)) ]]; then
      log "WARN: 試行回数上限到達 (${attempt_count}回)。終了します。"
      break
    fi

    if execute_task "$next_task"; then
      success_count=$((success_count + 1))
    fi
  done

  log "=== auto_dev.sh 終了 (成功: ${success_count}件 / 試行: ${attempt_count}件) ==="
  notify "Auto Dev完了: 成功${success_count}件 / 試行${attempt_count}件"
}

main "$@"
