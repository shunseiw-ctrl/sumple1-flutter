#!/usr/bin/env bash
#
# health_check.sh — ALBAWORK自律開発環境ヘルスチェック
#
# 1コマンドで全体の健全性を確認する
# 使い方: bash scripts/health_check.sh
#

set -euo pipefail

PROJECT_DIR="/Users/albalize/Desktop/sumple1-flutter-main"
TODO_FILE="$PROJECT_DIR/TODO.md"
REPORT_FILE="$PROJECT_DIR/REPORT.md"
LOCK_FILE="/tmp/albawork_auto_dev.lock"
FAIL_COUNT_DIR="$PROJECT_DIR/.auto_dev/fail_counts"
LOG_DIR="$PROJECT_DIR/logs"

export PATH="/opt/homebrew/bin:/Users/albalize/flutter/bin:$PATH"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
warn() { echo -e "  ${YELLOW}!${NC} $*"; }
fail() { echo -e "  ${RED}✗${NC} $*"; }
info() { echo -e "  ${CYAN}ℹ${NC} $*"; }

errors=0
warnings=0

echo "================================================"
echo "  ALBAWORK 自律開発環境 ヘルスチェック"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================================"
echo ""

# ─── 1. 必須コマンド ─────────────────────────────────
echo "1. 必須コマンド"
for cmd in claude gh flutter git jq curl; do
  if command -v "$cmd" &>/dev/null; then
    ok "$cmd: $(command -v "$cmd")"
  else
    fail "$cmd: 見つかりません"
    errors=$((errors + 1))
  fi
done
echo ""

# ─── 2. GitHub認証 ───────────────────────────────────
echo "2. GitHub認証"
if gh auth status &>/dev/null; then
  ok "gh: 認証済み"
else
  fail "gh: 未認証 → gh auth login を実行"
  errors=$((errors + 1))
fi
echo ""

# ─── 3. ロックファイル ───────────────────────────────
echo "3. ロックファイル"
if [[ -f "$LOCK_FILE" ]]; then
  lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
  if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
    info "auto_dev.py 実行中 (PID: $lock_pid)"
  else
    warn "staleロックファイルあり (PID: $lock_pid は存在しない)"
    warn "→ rm $LOCK_FILE で削除可能"
    warnings=$((warnings + 1))
  fi
else
  ok "ロックなし（待機中）"
fi
echo ""

# ─── 4. TODO.md ステータス ───────────────────────────
echo "4. TODO.md ステータス"
if [[ -f "$TODO_FILE" ]]; then
  pending=$(grep -c '^\- \[ \]' "$TODO_FILE" 2>/dev/null || true)
  pending=${pending:-0}
  in_progress=$(grep -c '^\- \[x\].*session:' "$TODO_FILE" 2>/dev/null || true)
  in_progress=${in_progress:-0}
  done_count=$(grep -c '^\- \[x\].*PR #' "$TODO_FILE" 2>/dev/null || true)
  done_count=${done_count:-0}
  failed=$(grep -c '^\- \[x\].*FAILED:' "$TODO_FILE" 2>/dev/null || true)
  failed=${failed:-0}
  info "PENDING: ${pending}件 / IN_PROGRESS: ${in_progress}件 / DONE: ${done_count}件 / FAILED: ${failed}件"
  if [[ "$in_progress" -gt 0 && ! -f "$LOCK_FILE" ]]; then
    warn "IN_PROGRESSのタスクがあるがauto_dev.pyは実行中でない（前回異常終了の可能性）"
    warnings=$((warnings + 1))
  fi
else
  fail "TODO.md が見つかりません"
  errors=$((errors + 1))
fi
echo ""

# ─── 5. 失敗カウント ────────────────────────────────
echo "5. 失敗カウント"
if [[ -d "$FAIL_COUNT_DIR" ]]; then
  fail_files=$(ls "$FAIL_COUNT_DIR"/issue_* 2>/dev/null || true)
  if [[ -n "$fail_files" ]]; then
    for f in $fail_files; do
      issue_num=$(basename "$f" | sed 's/issue_//')
      count=$(cat "$f")
      if [[ "$count" -ge 3 ]]; then
        fail "#${issue_num}: ${count}回失敗（FAILED上限到達）"
      else
        warn "#${issue_num}: ${count}回失敗"
      fi
    done
  else
    ok "失敗カウントなし"
  fi
else
  ok "失敗カウントなし"
fi
echo ""

# ─── 6. launchdジョブ ────────────────────────────────
echo "6. launchdジョブ"
for plist in com.albawork.issue-watcher com.albawork.nightly-dev; do
  if launchctl list "$plist" &>/dev/null; then
    ok "$plist: ロード済み"
  else
    if [[ -f "$HOME/Library/LaunchAgents/${plist}.plist" ]]; then
      warn "$plist: plistあるが未ロード → launchctl load ~/Library/LaunchAgents/${plist}.plist"
      warnings=$((warnings + 1))
    else
      warn "$plist: plistなし"
      warnings=$((warnings + 1))
    fi
  fi
done
echo ""

# ─── 7. ログファイル ────────────────────────────────
echo "7. ログファイル"
if [[ -d "$LOG_DIR" ]]; then
  log_count=$(find "$LOG_DIR" -name "*.log" 2>/dev/null | wc -l | tr -d ' ')
  log_size=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
  info "ログ数: ${log_count}ファイル / サイズ: ${log_size}"
  # 最新のauto_devログエントリ
  if [[ -f "$LOG_DIR/auto_dev.log" ]]; then
    last_entry=$(tail -1 "$LOG_DIR/auto_dev.log" 2>/dev/null || echo "なし")
    info "最新ログ: $last_entry"
  fi
else
  warn "ログディレクトリなし"
fi
echo ""

# ─── 8. Gitブランチ状態 ─────────────────────────────
echo "8. Gitブランチ状態"
cd "$PROJECT_DIR"
current_branch=$(git branch --show-current 2>/dev/null || echo "不明")
info "現在のブランチ: $current_branch"
auto_branches=$(git branch --list 'auto/*' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$auto_branches" -gt 5 ]]; then
  warn "autoブランチが${auto_branches}本溜まっています（整理推奨）"
  warnings=$((warnings + 1))
else
  info "autoブランチ: ${auto_branches}本"
fi
# 未マージPR
open_prs=$(gh pr list --state open --json number 2>/dev/null | jq length 2>/dev/null || echo "不明")
if [[ "$open_prs" != "不明" && "$open_prs" -gt 5 ]]; then
  warn "未マージPRが${open_prs}件（マージ推奨）"
  warnings=$((warnings + 1))
else
  info "未マージPR: ${open_prs}件"
fi
echo ""

# ─── 9. REPORT.md 直近結果 ──────────────────────────
echo "9. REPORT.md 直近結果"
if [[ -f "$REPORT_FILE" && -s "$REPORT_FILE" ]]; then
  # 最新エントリのステータスを取得
  last_status=$(grep '^\- \*\*ステータス\*\*:' "$REPORT_FILE" | head -1 | sed 's/.*: //')
  last_task=$(grep '^## [0-9]' "$REPORT_FILE" | head -1 | sed 's/^## //')
  if [[ -n "$last_status" ]]; then
    if [[ "$last_status" == "成功" ]]; then
      ok "直近: $last_task → $last_status"
    else
      warn "直近: $last_task → $last_status"
    fi
  fi
else
  info "REPORT.md: まだ記録なし"
fi
echo ""

# ─── 10. LINE通知設定 ────────────────────────────────
echo "10. 外部通知"
if [[ -n "${LINE_CHANNEL_TOKEN:-}" && -n "${LINE_USER_ID:-}" ]]; then
  ok "LINE Messaging API: 設定済み"
elif [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
  ok "Slack webhook: 設定済み"
else
  warn "外部通知: 未設定（LINE_CHANNEL_TOKEN+LINE_USER_ID または SLACK_WEBHOOK_URL）"
  warnings=$((warnings + 1))
fi
echo ""

# ─── 11. 実行メトリクス ──────────────────────────────
echo "11. 実行メトリクス"
METRICS_FILE="$PROJECT_DIR/.auto_dev/metrics.json"
if [[ -f "$METRICS_FILE" ]]; then
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
try:
    data = json.load(open('$METRICS_FILE'))
    s = data.get('summary', {})
    if s:
        rate = s.get('success_rate', 0) * 100
        total = s.get('total_runs', 0)
        succ = s.get('successes', 0)
        avg = s.get('avg_duration_seconds', 0) / 60
        print(f'  ℹ 成功率: {rate:.0f}% ({succ}/{total})')
        print(f'  ℹ 平均実行時間: {avg:.0f}分')
        by_type = s.get('by_type', {})
        if by_type:
            parts = [f'{t}={int(v[\"success_rate\"]*100)}%' for t,v in by_type.items()]
            print(f'  ℹ タイプ別: {\", \".join(parts)}')
    else:
        print('  ℹ まだ実行記録がありません')
except Exception as e:
    print(f'  ! メトリクス読込エラー: {e}')
" 2>/dev/null || warn "メトリクス表示に失敗"
  else
    warn "python3が見つかりません"
  fi
else
  info "メトリクスファイル未作成（初回実行後に作成されます）"
fi
echo ""

# ─── サマリー ────────────────────────────────────────
echo "================================================"
if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
  echo -e "  ${GREEN}全項目正常${NC}"
elif [[ $errors -eq 0 ]]; then
  echo -e "  ${YELLOW}警告: ${warnings}件${NC}（エラーなし）"
else
  echo -e "  ${RED}エラー: ${errors}件${NC} / ${YELLOW}警告: ${warnings}件${NC}"
fi
echo "================================================"
