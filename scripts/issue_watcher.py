#!/usr/bin/env python3
"""
issue_watcher.py — GitHub Issue監視 → TODO.md追記 → auto_dev.py呼び出し

label:auto のIssueを監視し、TODO.mdに追記する
"""

import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# パス設定
sys.path.insert(0, str(Path(__file__).resolve().parent))

from lib.config import PROJECT_DIR, LOG_DIR, LOCK_FILE
from lib.task_manager import TaskManager
from lib.github_service import GitHubService
from lib.lock_manager import LockManager

# PATH設定（launchd環境用）
os.environ["PATH"] = f"/opt/homebrew/bin:/Users/albalize/flutter/bin:{os.environ.get('PATH', '')}"


def timestamp() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M")


def log(message: str) -> None:
    """ログ出力"""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    line = f"[{timestamp()}] [issue_watcher] {message}"
    print(line, flush=True)
    try:
        with open(LOG_DIR / "issue_watcher.log", "a") as f:
            f.write(line + "\n")
    except OSError:
        pass


def main() -> None:
    log("=== Issue監視開始 ===")

    github = GitHubService()
    task_manager = TaskManager()

    # label:auto のオープンIssueを取得
    issues = github.list_auto_issues()

    if not issues:
        log("autoラベルのIssueなし")
        return

    # 既存Issue番号を取得
    existing = task_manager.get_all_issue_numbers()

    new_tasks = 0
    for issue in issues:
        if issue.number in existing:
            log(f"スキップ: #{issue.number} (既にTODO.mdに存在)")
            continue

        log(f"新規タスク追加: #{issue.number} {issue.title}")
        task_manager.add_to_pending(issue.number, issue.title)
        new_tasks += 1

    log(f"新規タスク: {new_tasks}件追加")

    # 新規タスクがあり、auto_dev.pyが実行中でなければ起動
    if new_tasks > 0 and not LockManager.is_locked():
        log("auto_dev.py を起動します")
        proc = subprocess.Popen(
            ["python3", str(PROJECT_DIR / "scripts" / "auto_dev.py")],
            cwd=str(PROJECT_DIR),
            stdout=open(LOG_DIR / "auto_dev_triggered.log", "a"),
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        log(f"auto_dev.py を起動しました (PID: {proc.pid})")
    elif LockManager.is_locked():
        log("auto_dev.py は既に実行中（スキップ）")

    log("=== Issue監視完了 ===")


if __name__ == "__main__":
    main()
