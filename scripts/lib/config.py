"""設定・定数管理モジュール"""

import os
from pathlib import Path

# パス
PROJECT_DIR = Path("/Users/albalize/Desktop/sumple1-flutter-main")
SCRIPTS_DIR = PROJECT_DIR / "scripts"
TODO_FILE = PROJECT_DIR / "TODO.md"
REPORT_FILE = PROJECT_DIR / "REPORT.md"
LOCK_FILE = Path("/tmp/albawork_auto_dev.lock")
FAIL_COUNT_DIR = PROJECT_DIR / ".auto_dev" / "fail_counts"
METRICS_FILE = PROJECT_DIR / ".auto_dev" / "metrics.json"
LOG_DIR = PROJECT_DIR / "logs"
PROMPTS_DIR = SCRIPTS_DIR / "prompts"
SYSTEM_PROMPT_FILE = PROMPTS_DIR / "system_prompt.txt"
TASK_PROMPT_TEMPLATE = PROMPTS_DIR / "task_prompt.template"

# 閾値
MAX_RETRIES = 2
MAX_FAIL_TOTAL = 3
TASK_TIMEOUT = 1800  # 30分（品質パイプライン除去のため短縮）
MAX_TURNS = 100  # 複雑なタスク+テスト修正ループ用に十分なバッファ
LOG_RETENTION_DAYS = 7
REPORT_MAX_ENTRIES = 50
DEFAULT_MAX_TASKS = 1

# 通知（環境変数から）
LINE_CHANNEL_TOKEN = os.environ.get("LINE_CHANNEL_TOKEN", "")
LINE_USER_ID = os.environ.get("LINE_USER_ID", "")
SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL", "")

# 自動マージ対象プレフィックス
AUTO_MERGE_PREFIXES = ("test:", "fix:", "refactor:", "chore:", "docs:")
MANUAL_REVIEW_PREFIXES = ("feat:",)
