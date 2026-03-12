#!/bin/bash
# KPI テストデータ シードスクリプト（Firebase REST API版）
# 使い方: cd functions && bash scripts/seed_kpi_data.sh

set -e

PROJECT_ID="alba-work"
ACCESS_TOKEN=$(gcloud auth print-access-token --account=albaworks.info@gmail.com 2>/dev/null || firebase login:ci --no-localhost 2>/dev/null)
BASE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"

echo "Firebase REST API でKPIテストデータを投入します..."

# ヘルパー関数: Firestoreドキュメント作成/更新
create_doc() {
  local collection="$1"
  local doc_id="$2"
  local json_body="$3"

  curl -s -X PATCH \
    "${BASE_URL}/${collection}/${doc_id}?updateMask.fieldPaths=*" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${json_body}" > /dev/null

  echo "✅ ${collection}/${doc_id}"
}

# 現在の日付情報
NOW_YEAR=$(date +%Y)
NOW_MONTH=$(date +%m)
NOW_DAY=$(date +%d)
CURRENT_MONTH_KEY="${NOW_YEAR}-${NOW_MONTH}"

# 前月計算
if [ "$NOW_MONTH" = "01" ]; then
  PREV_YEAR=$((NOW_YEAR - 1))
  PREV_MONTH="12"
else
  PREV_YEAR=$NOW_YEAR
  PREV_MONTH=$(printf "%02d" $((10#$NOW_MONTH - 1)))
fi
PREV_MONTH_KEY="${PREV_YEAR}-${PREV_MONTH}"

echo ""
echo "=== stats/realtime ==="
create_doc "stats" "realtime" '{
  "fields": {
    "totalJobs": {"integerValue": "24"},
    "totalApplications": {"integerValue": "87"},
    "totalUsers": {"integerValue": "156"},
    "pendingApplications": {"integerValue": "5"},
    "updatedAt": {"timestampValue": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
  }
}'

echo ""
echo "=== kpi_daily (直近7日分) ==="
for i in 6 5 4 3 2 1 0; do
  DATE_KEY=$(date -v-${i}d +%Y-%m-%d)
  APPS=$((RANDOM % 12 + 2))
  EARNINGS=$((RANDOM % 50000 + 10000))
  USERS=$((RANDOM % 8 + 1))
  JOBS=$((RANDOM % 5 + 1))
  CHATS=$((RANDOM % 15 + 3))

  create_doc "kpi_daily" "${DATE_KEY}" '{
    "fields": {
      "dateKey": {"stringValue": "'"${DATE_KEY}"'"},
      "newApplications": {"integerValue": "'"${APPS}"'"},
      "dailyEarnings": {"integerValue": "'"${EARNINGS}"'"},
      "newUsers": {"integerValue": "'"${USERS}"'"},
      "newJobs": {"integerValue": "'"${JOBS}"'"},
      "activeChats": {"integerValue": "'"${CHATS}"'"},
      "createdAt": {"timestampValue": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
    }
  }'
done

echo ""
echo "=== kpi_monthly (当月: ${CURRENT_MONTH_KEY}) ==="
create_doc "kpi_monthly" "${CURRENT_MONTH_KEY}" '{
  "fields": {
    "monthKey": {"stringValue": "'"${CURRENT_MONTH_KEY}"'"},
    "mau": {"integerValue": "89"},
    "monthlyEarnings": {"integerValue": "1250000"},
    "jobFillRate": {"doubleValue": 0.72},
    "totalJobs": {"integerValue": "24"},
    "totalUsers": {"integerValue": "156"},
    "totalApplications": {"integerValue": "42"},
    "createdAt": {"timestampValue": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
  }
}'

echo ""
echo "=== kpi_monthly (前月: ${PREV_MONTH_KEY}) ==="
create_doc "kpi_monthly" "${PREV_MONTH_KEY}" '{
  "fields": {
    "monthKey": {"stringValue": "'"${PREV_MONTH_KEY}"'"},
    "mau": {"integerValue": "67"},
    "monthlyEarnings": {"integerValue": "980000"},
    "jobFillRate": {"doubleValue": 0.58},
    "totalJobs": {"integerValue": "18"},
    "totalUsers": {"integerValue": "132"},
    "totalApplications": {"integerValue": "35"},
    "createdAt": {"timestampValue": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
  }
}'

echo ""
echo "🎉 全KPIテストデータの投入完了！"
echo "   アプリのダッシュボードを下に引いてリフレッシュしてください。"
