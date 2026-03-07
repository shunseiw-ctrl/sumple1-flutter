#!/usr/bin/env bash
# E2Eテスト全自動オーケストレーター
# Usage:
#   bash scripts/e2e_test.sh              # 全フロー実行
#   bash scripts/e2e_test.sh --skip-build # ビルドスキップ
#   bash scripts/e2e_test.sh --no-shutdown # テスト後シミュレータ維持
#   bash scripts/e2e_test.sh --flow maestro/04_login_page.yaml  # 特定フロー
set -euo pipefail

# ==== 定数 ====
SIM_UDID="F200D5B9-77FB-4F9F-95D1-FE5C3A1ED365"
APP_BUNDLE_ID="com.albawork.app"
APP_PATH="build/ios/Debug-iphonesimulator/Runner.app"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RESULTS_DIR="$PROJECT_ROOT/test-results"
SCREENSHOT_DIR="$RESULTS_DIR/screenshots/$TIMESTAMP"
REPORT_DIR="$RESULTS_DIR/reports"

# ==== オプション解析 ====
SKIP_BUILD=false
NO_SHUTDOWN=false
SPECIFIC_FLOW=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build) SKIP_BUILD=true; shift ;;
    --no-shutdown) NO_SHUTDOWN=true; shift ;;
    --flow) SPECIFIC_FLOW="$2"; shift 2 ;;
    *) echo "不明なオプション: $1"; exit 1 ;;
  esac
done

# ==== ユーティリティ ====
log() { echo "[E2E $(date +%H:%M:%S)] $*"; }
error() { echo "[E2E ERROR] $*" >&2; }

# エラー時自動スクショ
cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log "エラー発生 (exit=$exit_code) — スクショ取得中..."
    mkdir -p "$SCREENSHOT_DIR"
    xcrun simctl io "$SIM_UDID" screenshot "$SCREENSHOT_DIR/error_${TIMESTAMP}.png" 2>/dev/null || true
  fi
  if [[ "$NO_SHUTDOWN" == "false" ]]; then
    log "シミュレータ停止中..."
    xcrun simctl shutdown "$SIM_UDID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# ==== (A) 前提条件チェック ====
log "=== 前提条件チェック ==="
MISSING=()
command -v flutter >/dev/null 2>&1 || MISSING+=("flutter")
command -v xcrun >/dev/null 2>&1   || MISSING+=("xcrun")
command -v maestro >/dev/null 2>&1 || MISSING+=("maestro")
command -v java >/dev/null 2>&1    || MISSING+=("java")

if [[ ${#MISSING[@]} -gt 0 ]]; then
  error "未インストール: ${MISSING[*]}"
  exit 1
fi
log "全ツール確認済み: flutter, xcrun, maestro, java"

# ==== (B) 出力ディレクトリ作成 ====
mkdir -p "$SCREENSHOT_DIR" "$REPORT_DIR"
log "結果出力先: $RESULTS_DIR"

# ==== (C) シミュレータ起動 ====
log "=== シミュレータ起動 ==="
SIM_STATE=$(xcrun simctl list devices | grep "$SIM_UDID" | grep -o "(Booted)" || true)
if [[ -z "$SIM_STATE" ]]; then
  xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
  log "シミュレータ起動待機中..."
  xcrun simctl bootstatus "$SIM_UDID" -b
  log "シミュレータ起動完了"
else
  log "シミュレータは既に起動済み"
fi

# ==== (D) Flutterシミュレータ用ビルド ====
cd "$PROJECT_ROOT"

if [[ "$SKIP_BUILD" == "true" ]]; then
  log "=== ビルドスキップ ==="
  if [[ ! -d "$APP_PATH" ]]; then
    error "ビルド済みアプリが見つかりません: $APP_PATH"
    error "--skip-build を外して再実行してください"
    exit 1
  fi
else
  log "=== Flutterシミュレータ用ビルド ==="
  if flutter build ios --simulator --no-codesign 2>&1; then
    log "flutter build ios --simulator 成功"
  else
    log "flutter build 失敗 → xcodebuild フォールバック"
    cd ios
    xcodebuild build \
      -workspace Runner.xcworkspace \
      -scheme Runner \
      -configuration Debug \
      -sdk iphonesimulator \
      -destination "platform=iOS Simulator,id=$SIM_UDID" \
      ONLY_ACTIVE_ARCH=YES \
      2>&1 | tail -20
    cd "$PROJECT_ROOT"
    log "xcodebuild 成功"
  fi
fi

# ==== (E) アプリインストール ====
log "=== アプリインストール ==="
xcrun simctl install "$SIM_UDID" "$APP_PATH"
log "インストール完了"

# ==== (F) アプリ起動 ====
log "=== アプリ起動 ==="
xcrun simctl terminate "$SIM_UDID" "$APP_BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$SIM_UDID" "$APP_BUNDLE_ID"
log "アプリ起動完了 — 初期化待機 (5秒)..."
sleep 5

# ==== (G) Maestroテスト実行 ====
log "=== Maestroテスト実行 ==="
export MAESTRO_SCREENSHOT_DIR="$SCREENSHOT_DIR"

MAESTRO_EXIT=0
if [[ -n "$SPECIFIC_FLOW" ]]; then
  log "特定フロー実行: $SPECIFIC_FLOW"
  maestro test \
    --format junit \
    --output "$REPORT_DIR/junit_${TIMESTAMP}.xml" \
    "$SPECIFIC_FLOW" || MAESTRO_EXIT=$?
else
  log "全フロー実行: maestro/"
  maestro test \
    --format junit \
    --output "$REPORT_DIR/junit_${TIMESTAMP}.xml" \
    maestro/ || MAESTRO_EXIT=$?
fi

# ==== (H) レポート生成 ====
log "=== レポート生成 ==="
SUMMARY_FILE="$REPORT_DIR/summary_${TIMESTAMP}.txt"

{
  echo "=============================="
  echo "  E2Eテスト結果サマリー"
  echo "  実行日時: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "=============================="
  echo ""

  if [[ $MAESTRO_EXIT -eq 0 ]]; then
    echo "結果: 全テスト成功"
  else
    echo "結果: テスト失敗あり (exit=$MAESTRO_EXIT)"
  fi
  echo ""

  echo "スクリーンショット: $SCREENSHOT_DIR"
  echo "JUnitレポート: $REPORT_DIR/junit_${TIMESTAMP}.xml"
  echo ""

  # スクショ一覧
  if [[ -d "$SCREENSHOT_DIR" ]]; then
    echo "--- スクリーンショット一覧 ---"
    find "$SCREENSHOT_DIR" -name "*.png" -type f | sort
    echo ""
  fi

  # JUnit XMLサマリー（存在する場合）
  JUNIT_FILE="$REPORT_DIR/junit_${TIMESTAMP}.xml"
  if [[ -f "$JUNIT_FILE" ]]; then
    echo "--- JUnit XMLサマリー ---"
    # テスト数・失敗数を抽出
    TESTS=$(grep -o 'tests="[0-9]*"' "$JUNIT_FILE" | head -1 | grep -o '[0-9]*' || echo "N/A")
    FAILURES=$(grep -o 'failures="[0-9]*"' "$JUNIT_FILE" | head -1 | grep -o '[0-9]*' || echo "N/A")
    ERRORS=$(grep -o 'errors="[0-9]*"' "$JUNIT_FILE" | head -1 | grep -o '[0-9]*' || echo "N/A")
    echo "テスト数: $TESTS"
    echo "失敗: $FAILURES"
    echo "エラー: $ERRORS"
    echo ""

    # 失敗テストの詳細
    if grep -q '<failure' "$JUNIT_FILE" 2>/dev/null; then
      echo "--- 失敗テスト詳細 ---"
      grep -A5 '<failure' "$JUNIT_FILE" || true
      echo ""
    fi
  fi
} > "$SUMMARY_FILE"

cat "$SUMMARY_FILE"

# ==== 完了 ====
if [[ $MAESTRO_EXIT -eq 0 ]]; then
  log "=== E2Eテスト完了: 全成功 ==="
else
  log "=== E2Eテスト完了: 失敗あり ==="
  exit $MAESTRO_EXIT
fi
