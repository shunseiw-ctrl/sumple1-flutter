#!/usr/bin/env python3
"""
auto_dev.py — ALBAWORK自律開発オーケストレーター
auto_dev.shのPython書き換え版

使い方:
  python3 scripts/auto_dev.py              # PENDINGの最上位タスク1件を実行
  python3 scripts/auto_dev.py --all 3      # 成功3件まで順次実行
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

# パス設定（scripts/auto_dev.py → scripts/ からの相対）
sys.path.insert(0, str(Path(__file__).resolve().parent))

from lib.config import (
    LOG_DIR, FAIL_COUNT_DIR, DEFAULT_MAX_TASKS,
)
from lib.lock_manager import LockManager, LockError
from lib.task_manager import TaskManager
from lib.report_manager import ReportManager
from lib.git_service import GitService
from lib.github_service import GitHubService
from lib.validator import Validator
from lib.notifier import Notifier
from lib.metrics import MetricsManager
from lib.log_utils import log, rotate_logs
from lib.task_executor import execute_task

# PATH設定（launchd環境用）
os.environ["PATH"] = f"/opt/homebrew/bin:/Users/albalize/flutter/bin:{os.environ.get('PATH', '')}"

# ~/.zshrcから環境変数を補完（launchd/サブプロセスでは.zshrcが読まれないため）
# Issue 28: 自前パースを廃止し、zshでsource+env出力を使用
_zshrc = Path.home() / ".zshrc"
if _zshrc.exists():
    try:
        _result = subprocess.run(
            ["zsh", "-c", "source ~/.zshrc 2>/dev/null && env -0"],
            capture_output=True, text=True, timeout=10,
        )
        if _result.returncode == 0 and _result.stdout:
            for _entry in _result.stdout.split("\0"):
                if "=" in _entry:
                    _key, _, _val = _entry.partition("=")
                    if _key and not os.environ.get(_key):
                        os.environ[_key] = _val
    except (subprocess.TimeoutExpired, OSError):
        pass

# ネストされたClaudeセッション防止を回避
os.environ.pop("CLAUDECODE", None)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="ALBAWORK自律開発オーケストレーター")
    parser.add_argument(
        "--all",
        type=int,
        default=DEFAULT_MAX_TASKS,
        metavar="N",
        help=f"成功N件まで順次実行（デフォルト: {DEFAULT_MAX_TASKS}）",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    max_tasks = args.all

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    FAIL_COUNT_DIR.mkdir(parents=True, exist_ok=True)

    log("=== auto_dev.py 開始 ===")

    # サービス初期化
    task_manager = TaskManager()
    report_manager = ReportManager()
    git = GitService()
    github = GitHubService()
    validator = Validator()
    notifier = Notifier()
    metrics_mgr = MetricsManager()

    try:
        with LockManager() as lock:
            # gh認証チェック
            if not github.check_auth():
                log("FATAL: GitHub認証が無効です。gh auth login を実行してください")
                notifier.notify("FATAL", "GitHub認証切れ。自律開発を停止しました")
                return

            rotate_logs()
            report_manager.truncate()

            success_count = 0
            attempt_count = 0

            while success_count < max_tasks:
                task = task_manager.get_next_pending()
                if not task:
                    log("PENDINGタスクなし。終了します。")
                    break

                attempt_count += 1

                # 無限ループ防止
                if attempt_count > max_tasks * 3:
                    log(f"WARN: 試行回数上限到達 ({attempt_count}回)。終了します。")
                    break

                if execute_task(
                    task, task_manager, report_manager,
                    git, github, validator, notifier, metrics_mgr,
                ):
                    success_count += 1

            log(f"=== auto_dev.py 終了 (成功: {success_count}件 / 試行: {attempt_count}件) ===")
            notifier.notify("Auto Dev完了", f"成功{success_count}件 / 試行{attempt_count}件")

    except LockError as e:
        log(f"ERROR: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
