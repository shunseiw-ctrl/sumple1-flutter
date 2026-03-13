#!/usr/bin/env bash
#
# remote_setup.sh — リモートアクセス初期設定ヘルパー
#
# SSH、Tailscale、tmux、スリープ防止の設定確認とガイドを表示
#

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
warn() { echo -e "  ${YELLOW}!${NC} $*"; }
fail() { echo -e "  ${RED}✗${NC} $*"; }

echo "================================================"
echo "  ALBAWORK リモートアクセス設定チェック"
echo "================================================"
echo ""

# ─── 1. SSH (リモートログイン) ─────────────────────────
echo "1. SSH (リモートログイン)"
if systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
  ok "リモートログインが有効です"
else
  fail "リモートログインが無効です"
  echo "     → システム設定 > 一般 > 共有 > リモートログイン を有効にしてください"
  echo "     → または: sudo systemsetup -setremotelogin on"
fi
echo ""

# ─── 2. Tailscale ──────────────────────────────────────
echo "2. Tailscale (VPN)"
if command -v tailscale &>/dev/null; then
  ok "Tailscaleがインストールされています"
  local_ip=$(tailscale ip -4 2>/dev/null || echo "未接続")
  if [[ "$local_ip" != "未接続" ]]; then
    ok "Tailscale IP: $local_ip"
    echo "     → SSH接続: ssh $(whoami)@${local_ip}"
  else
    warn "Tailscaleが接続されていません"
    echo "     → Tailscaleアプリを起動してログインしてください"
  fi
else
  fail "Tailscaleがインストールされていません"
  echo "     → インストール: brew install --cask tailscale"
  echo "     → または: https://tailscale.com/download/mac"
fi
echo ""

# ─── 3. tmux ───────────────────────────────────────────
echo "3. tmux (セッション管理)"
if command -v tmux &>/dev/null; then
  ok "tmuxがインストールされています ($(tmux -V))"
  sessions=$(tmux list-sessions 2>/dev/null || echo "なし")
  if [[ "$sessions" != "なし" ]]; then
    ok "アクティブセッション:"
    echo "$sessions" | sed 's/^/     /'
  else
    warn "アクティブセッションなし"
  fi
else
  fail "tmuxがインストールされていません"
  echo "     → インストール: brew install tmux"
fi
echo ""

# ─── 4. スリープ防止 ──────────────────────────────────
echo "4. スリープ防止"
# caffeinate確認
if pgrep -x caffeinate &>/dev/null; then
  ok "caffeinateが実行中です"
else
  warn "caffeinateが実行されていません"
  echo "     → 起動: caffeinate -dis &"
  echo "     → (ディスプレイOFF + アイドルスリープ + システムスリープ 防止)"
fi

# pmset設定確認
sleep_val=$(pmset -g | grep "^\s*sleep" | head -1 | awk '{print $2}')
if [[ "$sleep_val" == "0" ]]; then
  ok "システムスリープ: 無効"
else
  warn "システムスリープ: ${sleep_val}分後"
  echo "     → 無効化: sudo pmset -a sleep 0"
fi

displaysleep_val=$(pmset -g | grep "displaysleep" | head -1 | awk '{print $2}')
echo "     ディスプレイスリープ: ${displaysleep_val:-不明}分後（ディスプレイのみなのでOK）"
echo ""

# ─── 5. Claude Code CLI ───────────────────────────────
echo "5. Claude Code CLI"
if command -v claude &>/dev/null; then
  ok "claude CLIが利用可能です"
  claude_ver=$(claude --version 2>/dev/null || echo "バージョン不明")
  echo "     バージョン: $claude_ver"
else
  fail "claude CLIが見つかりません"
  echo "     → インストール: npm install -g @anthropic-ai/claude-code"
fi
echo ""

# ─── 6. gh CLI ─────────────────────────────────────────
echo "6. GitHub CLI"
if command -v gh &>/dev/null; then
  ok "gh CLIが利用可能です"
  auth_status=$(gh auth status 2>&1 | head -1 || echo "未認証")
  echo "     $auth_status"
else
  fail "gh CLIが見つかりません"
  echo "     → インストール: brew install gh"
fi
echo ""

# ─── サマリー ──────────────────────────────────────────
echo "================================================"
echo "  リモート操作手順"
echo "================================================"
echo ""
echo "  # スマホ/リモートPCからSSH接続"
tailscale_ip=$(tailscale ip -4 2>/dev/null || echo "100.x.x.x")
echo "  ssh $(whoami)@${tailscale_ip}"
echo ""
echo "  # tmuxセッション"
echo "  tmux new -s claude               # 新規"
echo "  tmux attach -t claude            # 既存に接続"
echo ""
echo "  # 開発ディレクトリに移動してClaude起動"
echo "  cd ~/Desktop/sumple1-flutter-main"
echo "  claude                            # 対話モード"
echo ""
echo "  # 自律実行"
echo "  python3 scripts/auto_dev.py          # 1タスク"
echo "  python3 scripts/auto_dev.py --all 5  # 最大5タスク"
echo ""
echo "  # セッション切断（バックグラウンド継続）"
echo "  Ctrl+B → D"
echo ""
