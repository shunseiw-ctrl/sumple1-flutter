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
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

# パス設定（scripts/auto_dev.py → scripts/ からの相対）
sys.path.insert(0, str(Path(__file__).resolve().parent))

from lib.config import (
    PROJECT_DIR, LOG_DIR, FAIL_COUNT_DIR, LOCK_FILE,
    MAX_RETRIES, MAX_FAIL_TOTAL, TASK_TIMEOUT, MAX_TURNS,
    REPORT_MAX_ENTRIES, LOG_RETENTION_DAYS, DEFAULT_MAX_TASKS,
    PROMPTS_DIR, SYSTEM_PROMPT_FILE, TASK_PROMPT_TEMPLATE,
    AUTO_MERGE_PREFIXES,
)
from lib.lock_manager import LockManager, LockError
from lib.task_manager import TaskManager, Task
from lib.report_manager import ReportManager
from lib.claude_runner import ClaudeRunner
from lib.git_service import GitService, GitError
from lib.github_service import GitHubService, GitHubError
from lib.validator import Validator
from lib.notifier import Notifier
from lib.metrics import MetricsManager

# PATH設定（launchd環境用）
os.environ["PATH"] = f"/opt/homebrew/bin:/Users/albalize/flutter/bin:{os.environ.get('PATH', '')}"

# ネストされたClaudeセッション防止を回避
os.environ.pop("CLAUDECODE", None)


def timestamp() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M")


def log(message: str) -> None:
    """ログ出力"""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    line = f"[{timestamp()}] {message}"
    print(line, flush=True)
    try:
        with open(LOG_DIR / "auto_dev.log", "a") as f:
            f.write(line + "\n")
    except OSError:
        pass


def rotate_logs() -> None:
    """古いログファイルを削除"""
    if not LOG_DIR.exists():
        return
    cutoff = time.time() - LOG_RETENTION_DAYS * 86400
    for log_file in LOG_DIR.glob("*.log"):
        try:
            if log_file.stat().st_mtime < cutoff:
                log_file.unlink()
        except OSError:
            pass
    log(f"ログローテーション完了（{LOG_RETENTION_DAYS}日以上前のログを削除）")


def get_fail_count(issue_num: int) -> int:
    """累計失敗回数を取得"""
    count_file = FAIL_COUNT_DIR / f"issue_{issue_num}"
    try:
        return int(count_file.read_text().strip())
    except (FileNotFoundError, ValueError):
        return 0


def increment_fail_count(issue_num: int) -> None:
    """失敗回数をインクリメント"""
    FAIL_COUNT_DIR.mkdir(parents=True, exist_ok=True)
    current = get_fail_count(issue_num)
    (FAIL_COUNT_DIR / f"issue_{issue_num}").write_text(str(current + 1))


def reset_fail_count(issue_num: int) -> None:
    """失敗回数をリセット"""
    try:
        (FAIL_COUNT_DIR / f"issue_{issue_num}").unlink()
    except FileNotFoundError:
        pass


def build_prompt(issue_num: int, task_title: str, issue_body: str) -> str:
    """Claude用プロンプトを構築"""
    body_content = issue_body or "（Issue本文なし。タスクタイトルから判断して実装してください）"

    if TASK_PROMPT_TEMPLATE.exists():
        template = TASK_PROMPT_TEMPLATE.read_text()
        prompt = template.replace("{{ISSUE_NUM}}", str(issue_num))
        prompt = prompt.replace("{{TASK_TITLE}}", task_title)
        prompt = prompt.replace("{{ISSUE_BODY}}", body_content)
        return prompt

    return f"""以下のタスクを実装してください。
#{issue_num} {task_title}
{body_content}"""


def make_branch_name(issue_num: int, task_title: str) -> str:
    """ブランチ名を生成"""
    safe = re.sub(r"[^a-zA-Z0-9-]", "-", task_title.replace(" ", "-").replace(":", "-"))
    safe = re.sub(r"-+", "-", safe).strip("-")[:40]
    return f"auto/{issue_num}-{safe}"


def execute_task(
    task: Task,
    task_manager: TaskManager,
    report_manager: ReportManager,
    claude_runner: ClaudeRunner,
    git: GitService,
    github: GitHubService,
    validator: Validator,
    notifier: Notifier,
    metrics: MetricsManager,
) -> bool:
    """タスクを1件実行"""
    issue_num = task.issue_number
    task_title = task.title
    branch_name = make_branch_name(issue_num, task_title)
    session_id = str(int(time.time()))[-7:]
    start_time = time.time()

    # 累計失敗カウントチェック
    total_fails = get_fail_count(issue_num)
    if total_fails >= MAX_FAIL_TOTAL:
        log(f"SKIP: #{issue_num} は累計{total_fails}回失敗済み → FAILED固定")
        task_manager.move_to_in_progress(task, session_id)
        task_manager.move_to_failed(task, f"累計{total_fails}回失敗")
        report_manager.write_report(
            issue_num, task_title, "FAILED（永久停止）",
            notes=f"累計{total_fails}回失敗で自動停止",
        )
        notifier.notify("FAILED", f"#{issue_num} {task_title}（累計{total_fails}回失敗）")
        metrics.record(
            issue_number=issue_num, task_type=task.task_type, success=False,
            retries=0, duration_seconds=0, claude_exit_code=-1,
            analyze_pass=False, test_pass=False,
            error_message=f"累計{total_fails}回失敗で永久停止",
        )
        return False

    log(f"タスク開始: #{issue_num} {task_title} (累計失敗: {total_fails}/{MAX_FAIL_TOTAL})")
    notifier.notify("タスク開始", f"#{issue_num} {task_title}")

    # Issue本文を取得
    try:
        issue_body = github.get_issue_body(issue_num)
    except GitHubError:
        issue_body = ""

    # git stash + ブランチ作成
    try:
        git.stash_if_dirty()
        git.create_branch(branch_name)
    except GitError as e:
        # ブランチが既存の場合はチェックアウト
        try:
            git.checkout(branch_name)
        except GitError:
            log(f"ERROR: ブランチ操作失敗: {e}")
            return False

    # IN_PROGRESSに移動
    task_manager.move_to_in_progress(task, session_id)

    # プロンプト構築
    prompt = build_prompt(issue_num, task_title, issue_body)

    # Claude用のallowedToolsリスト（Agent含む — 品質パイプライン用）
    allowed_tools = (
        "Read,Grep,Glob,Edit,Write,Agent,"
        "Bash(flutter *),Bash(dart *),Bash(git add*),Bash(git commit*),"
        "Bash(git status*),Bash(git diff*),Bash(git log*),Bash(ls*),Bash(mkdir*),Bash(cat*),"
        "Bash(bash scripts/e2e_test.sh*),Bash(xcrun *),Bash(maestro *)"
    )

    retry_count = 0
    claude_exit_code = -1
    analyze_pass = False
    test_pass = False
    test_count = 0

    while retry_count < MAX_RETRIES:
        log(f"実行試行 {retry_count + 1}/{MAX_RETRIES}")

        # リトライ時はブランチをリセット
        if retry_count > 0:
            log("リトライ前: ブランチをmainベースにリセット")
            git.reset_hard("main")

        # Claude実行（subprocess直接）
        system_prompt = ""
        if SYSTEM_PROMPT_FILE.exists():
            system_prompt = SYSTEM_PROMPT_FILE.read_text()

        cmd = [
            "claude", "-p", prompt,
            "--allowedTools", allowed_tools,
            "--max-turns", str(MAX_TURNS),
            "--output-format", "text",
        ]
        if system_prompt:
            cmd.extend(["--append-system-prompt", system_prompt])

        log("Claude実行開始...")
        claude_result = _run_claude_with_timeout(cmd, TASK_TIMEOUT)
        claude_exit_code = claude_result["exit_code"]
        claude_output = claude_result["stdout"]
        timed_out = claude_result["timed_out"]

        log(f"Claude終了コード: {claude_exit_code}")

        # タイムアウト
        if timed_out:
            log(f"WARN: タイムアウト ({TASK_TIMEOUT}秒)")
            claude_exit_code = 124

        # 「要確認」チェック
        if "要確認:" in claude_output:
            concerns = [
                line for line in claude_output.splitlines()
                if "要確認:" in line
            ][:3]
            concern_text = "\n".join(concerns)
            log(f"要確認事項あり: {concern_text}")
            report_manager.write_report(
                issue_num, task_title, "要確認", notes=concern_text,
            )
            increment_fail_count(issue_num)
            task_manager.move_back_to_pending(task)
            notifier.notify("要確認", f"#{issue_num} {task_title}")
            duration = time.time() - start_time
            metrics.record(
                issue_number=issue_num, task_type=task.task_type, success=False,
                retries=retry_count, duration_seconds=duration,
                claude_exit_code=claude_exit_code,
                analyze_pass=False, test_pass=False,
                error_message="要確認事項あり",
            )
            _cleanup_branch(git, branch_name)
            return False

        # Claude実行失敗
        if claude_exit_code != 0:
            log(f"ERROR: Claude実行失敗 (exit: {claude_exit_code})")
            retry_count += 1
            if retry_count < MAX_RETRIES:
                log("リトライします...")
                time.sleep(10)
                continue
            report_manager.write_report(
                issue_num, task_title, "失敗",
                notes=f"Claude実行エラー (exit: {claude_exit_code})",
            )
            increment_fail_count(issue_num)
            task_manager.move_back_to_pending(task)
            notifier.notify("失敗", f"#{issue_num} {task_title}")
            duration = time.time() - start_time
            metrics.record(
                issue_number=issue_num, task_type=task.task_type, success=False,
                retries=retry_count, duration_seconds=duration,
                claude_exit_code=claude_exit_code,
                analyze_pass=False, test_pass=False,
                error_message=f"Claude exit {claude_exit_code}",
            )
            _cleanup_branch(git, branch_name)
            return False

        # コミット有無チェック
        commit_count = git.commit_count(branch_name)
        if commit_count == 0:
            log("WARN: コミットなし")
            retry_count += 1
            if retry_count < MAX_RETRIES:
                log("リトライします...")
                time.sleep(10)
                continue
            report_manager.write_report(
                issue_num, task_title, "失敗", changed_files="0件",
                notes="コミットなし",
            )
            increment_fail_count(issue_num)
            task_manager.move_back_to_pending(task)
            notifier.notify("失敗", f"#{issue_num} コミットなし")
            duration = time.time() - start_time
            metrics.record(
                issue_number=issue_num, task_type=task.task_type, success=False,
                retries=retry_count, duration_seconds=duration,
                claude_exit_code=claude_exit_code,
                analyze_pass=False, test_pass=False,
                error_message="コミットなし",
            )
            _cleanup_branch(git, branch_name)
            return False

        # ─── 検証フェーズ ───
        log("検証開始: flutter analyze")
        analyze_result = validator.run_analyze()
        analyze_pass = analyze_result.passed

        if not analyze_pass:
            log(f"ERROR: flutter analyze 失敗 (errors: {analyze_result.error_count})")
            retry_count += 1
            if retry_count < MAX_RETRIES:
                log("リトライします...")
                continue
            report_manager.write_report(
                issue_num, task_title, "失敗", test_result="analyze失敗",
                notes=f"analyze errors: {analyze_result.error_count}",
            )
            increment_fail_count(issue_num)
            task_manager.move_back_to_pending(task)
            notifier.notify("失敗", f"#{issue_num} analyze エラー")
            duration = time.time() - start_time
            metrics.record(
                issue_number=issue_num, task_type=task.task_type, success=False,
                retries=retry_count, duration_seconds=duration,
                claude_exit_code=claude_exit_code,
                analyze_pass=False, test_pass=False,
                error_message="flutter analyze失敗",
            )
            _cleanup_branch(git, branch_name)
            return False

        log("flutter analyze: OK")

        log("検証開始: flutter test")
        test_result = validator.run_test()
        test_pass = test_result.all_passed
        test_count = test_result.total

        if not test_pass:
            log(f"ERROR: flutter test 失敗 (passed: {test_result.passed}, failed: {test_result.failed})")
            retry_count += 1
            if retry_count < MAX_RETRIES:
                log("リトライします...")
                continue
            report_manager.write_report(
                issue_num, task_title, "失敗", test_result="test失敗",
                notes="テスト失敗",
            )
            increment_fail_count(issue_num)
            task_manager.move_back_to_pending(task)
            notifier.notify("失敗", f"#{issue_num} テスト失敗")
            duration = time.time() - start_time
            metrics.record(
                issue_number=issue_num, task_type=task.task_type, success=False,
                retries=retry_count, duration_seconds=duration,
                claude_exit_code=claude_exit_code,
                analyze_pass=True, test_pass=False,
                error_message="flutter test失敗",
            )
            _cleanup_branch(git, branch_name)
            return False

        test_pass_text = f"All {test_count} tests passed"
        log(f"検証成功: {test_pass_text}")

        # ─── 成功：push + PR作成 ───
        changed_files = git.changed_files()
        claude_summary = claude_output[-4000:] if len(claude_output) > 4000 else claude_output

        log("git push開始")
        try:
            git.push(branch_name)
        except GitError as e:
            log(f"ERROR: git push 失敗: {e}")
            report_manager.write_report(
                issue_num, task_title, "失敗",
                changed_files=changed_files or "-",
                test_result=test_pass_text,
                notes="git push失敗",
            )
            increment_fail_count(issue_num)
            task_manager.move_back_to_pending(task)
            notifier.notify("失敗", f"#{issue_num} git push失敗（ネットワーク確認要）")
            _cleanup_branch(git, branch_name)
            duration = time.time() - start_time
            metrics.record(
                issue_number=issue_num, task_type=task.task_type, success=False,
                retries=retry_count, duration_seconds=duration,
                claude_exit_code=claude_exit_code,
                analyze_pass=True, test_pass=True, test_count=test_count,
                error_message="git push失敗",
            )
            return False

        # PR作成
        pr_body = f"""## Summary
- Auto-generated by auto_dev.py
- Task: #{issue_num} {task_title}

Closes #{issue_num}

## Verification
- flutter analyze: 0 errors
- flutter test: {test_pass_text}

## Changes
{changed_files}

## Claude Output (auto-generated)
<details>
<summary>Claude実行ログ（クリックで展開）</summary>

```
{claude_summary}
```

</details>

---
Generated by ALBAWORK Auto Dev System"""

        try:
            pr_number = github.create_pr(
                title=f"#{issue_num} {task_title}",
                body=pr_body,
                branch=branch_name,
            )
        except GitHubError as e:
            log(f"WARN: PR作成失敗: {e}")
            pr_number = 0

        log(f"PR作成: #{pr_number}")

        task_manager.move_to_done(task, pr_number)
        report_manager.write_report(
            issue_num, task_title, "成功",
            changed_files=changed_files or "-",
            test_result=f"analyze OK / {test_pass_text}",
            pr_number=pr_number,
            notes="なし",
        )
        reset_fail_count(issue_num)

        duration = time.time() - start_time
        auto_merged = task_title.startswith(AUTO_MERGE_PREFIXES)
        metrics.record(
            issue_number=issue_num, task_type=task.task_type, success=True,
            retries=retry_count, duration_seconds=duration,
            claude_exit_code=claude_exit_code,
            analyze_pass=True, test_pass=True, test_count=test_count,
            pr_number=pr_number, auto_merged=auto_merged,
        )

        notifier.notify("成功", f"#{issue_num} {task_title} → PR #{pr_number}")
        log(f"タスク完了: #{issue_num} → PR #{pr_number}")

        # mainに戻す
        _cleanup_branch(git, branch_name, delete=False)
        return True

    # whileが完走（全リトライ失敗）— ここには来ないはずだが安全策
    _cleanup_branch(git, branch_name)
    return False


def _run_claude_with_timeout(cmd: list, timeout: int) -> dict:
    """タイムアウト付きでClaudeを実行"""
    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=str(PROJECT_DIR),
        )

        timed_out = False

        def kill_proc():
            nonlocal timed_out
            timed_out = True
            try:
                proc.terminate()
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    proc.kill()
            except OSError:
                pass

        timer = __import__("threading").Timer(timeout, kill_proc)
        timer.start()

        try:
            stdout_bytes, stderr_bytes = proc.communicate()
        finally:
            timer.cancel()

        return {
            "exit_code": proc.returncode if not timed_out else 124,
            "stdout": stdout_bytes.decode("utf-8", errors="replace"),
            "stderr": stderr_bytes.decode("utf-8", errors="replace"),
            "timed_out": timed_out,
        }
    except FileNotFoundError:
        return {
            "exit_code": 127,
            "stdout": "",
            "stderr": "claude: command not found",
            "timed_out": False,
        }


def _cleanup_branch(git: GitService, branch_name: str, delete: bool = True) -> None:
    """mainに戻してブランチをクリーンアップ"""
    try:
        git.stash_if_dirty()
        git.checkout("main")
        if delete:
            git.delete_branch(branch_name)
    except GitError:
        pass


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
    claude_runner = ClaudeRunner()
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
                    task, task_manager, report_manager, claude_runner,
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
