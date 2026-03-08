#!/usr/bin/env bash
# ストア申請用スクリーンショット配置スクリプト
# 使い方: bash scripts/copy_screenshots.sh <スクリーンショットフォルダパス>
#
# スクリーンショットの命名規則:
#   01_login.png      → ログイン/初期画面
#   02_home.png       → 求人一覧（ホーム）
#   03_job_detail.png → 求人詳細
#   04_map_search.png → 地図検索
#   05_chat.png       → チャット画面

set -euo pipefail

SOURCE_DIR="${1:-.}"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IOS_DIR="$PROJECT_ROOT/ios/fastlane/screenshots/ja"
ANDROID_DIR="$PROJECT_ROOT/android/fastlane/metadata/android/ja-JP/images/phoneScreenshots"

mkdir -p "$IOS_DIR" "$ANDROID_DIR"

echo "=== スクリーンショット配置 ==="
echo "ソース: $SOURCE_DIR"
echo ""

count=0
for img in "$SOURCE_DIR"/*.{png,PNG,jpg,JPG,jpeg,JPEG} 2>/dev/null; do
  [ -f "$img" ] || continue
  filename=$(basename "$img")

  # iOS用にコピー
  cp "$img" "$IOS_DIR/$filename"
  echo "  iOS: $IOS_DIR/$filename"

  # Android用にコピー
  cp "$img" "$ANDROID_DIR/$filename"
  echo "  Android: $ANDROID_DIR/$filename"

  count=$((count + 1))
done

echo ""
echo "配置完了: ${count}枚"
echo ""
echo "iOS: $IOS_DIR/"
echo "Android: $ANDROID_DIR/"

if [ $count -lt 5 ]; then
  echo ""
  echo "⚠ 最低5枚のスクリーンショットが必要です（現在: ${count}枚）"
  echo ""
  echo "必要なスクリーンショット:"
  echo "  1. ログイン/初期画面 (01_login.png)"
  echo "  2. 求人一覧ホーム (02_home.png)"
  echo "  3. 求人詳細 (03_job_detail.png)"
  echo "  4. 地図検索 (04_map_search.png)"
  echo "  5. チャット画面 (05_chat.png)"
fi
