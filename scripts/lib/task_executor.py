"""タスク実行モジュール"""

import logging
import time

from lib.config import (
    LOG_DIR, FAIL_COUNT_DIR,
    MAX_RETRIES, MAX_FAIL_TOTAL, TASK_TIMEOUT, MAX_TURNS,
    SYSTEM_PROMPT_FILE,
    AUTO_MERGE_PREFIXES,
    RETRY_BASE_INTERVAL, RETRY_BACKOFF_FACTOR, RETRY_MAX_INTERVAL,
)
from lib.log_utils import log
from lib.prompt_builder import build_prompt, make_branch_name
from lib.task_manager import Task, TaskManager
from lib.report_manager import ReportManager
from lib.git_service import GitService, GitError
from lib.github_service import GitHubService, GitHubError
from lib.validator import Validator
from lib.notifier import Notifier
from lib.metrics import MetricsManager
from lib.claude_runner import ClaudeRunner

_logger = logging.getLogger("auto_dev")


def _stage(name: str) -> None:
    print(f"##STAGE:{name}##", flush=True)


def retry_sleep(retry_count: int) -> None:
    """指数バックオフ付きリトライスリープ"""
    interval = min(
        RETRY_BASE_INTERVAL * (RETRY_BACKOFF_FACTOR ** retry_count),
        RETRY_MAX_INTERVAL,
    )
    time.sleep(interval)


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


def _commit_todo(git: GitService, message: str) -> None:
    """TODO.mdの変更をmainにコミット（git pullによる上書き防止）"""
    try:
        git.add("TODO.md")
        git.commit(message)
    except Exception as e:
        _logger.warning("_commit_todo失敗: %s", e)


def _cleanup_branch(
    git: GitService,
    branch_name: str,
    delete: bool = True,
    stash_pop: bool = False,
) -> None:
    """mainに戻してブランチをクリーンアップ

    Issue 3: 例外握りつぶし修正
    Issue 10: stash汚染防止（checkout -- . + clean -fdで破棄）
    """
    # ブランチ上の変更を破棄（stashスタックを汚さない）
    try:
        git._run(["checkout", "--", "."], check=False)
        git._run(["clean", "-fd"], check=False)
    except GitError as e:
        _logger.warning("ブランチ上の変更破棄失敗（続行）: %s", e)

    # mainに戻る
    try:
        git.checkout("main")
    except GitError as e:
        _logger.critical("checkout mainに失敗: %s", e)
        raise

    # ブランチ削除
    if delete:
        try:
            git.delete_branch(branch_name)
        except GitError as e:
            _logger.warning("ブランチ削除失敗（続行）: %s", e)

    # 元のstashを復元
    if stash_pop:
        try:
            git.stash_pop()
        except GitError as e:
            _logger.warning("stash pop失敗（続行）: %s", e)


def execute_task(
    task: Task,
    task_manager: TaskManager,
    report_manager: ReportManager,
    git: GitService,
    github: GitHubService,
    validator: Validator,
    notifier: Notifier,
    metrics: MetricsManager,
) -> bool:
    """タスクを1件実行"""
    _stage("task_start")
    issue_num = task.issue_number
    task_title = task.title
    branch_name = make_branch_name(issue_num, task_title)
    session_id = str(int(time.time()))[-7:]
    start_time = time.time()

    # 累計失敗カウントチェック
    total_fails = get_fail_count(issue_num)
    if total_fails >= MAX_FAIL_TOTAL:
        log(f"SKIP: #{issue_num} は累計{total_fails}回失敗済み → FAILED固定")
        task_manager.move_to_failed(task, f"累計{total_fails}回失敗")
        _commit_todo(git, f"chore: #{issue_num} FAILED（累計{total_fails}回失敗）")
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
        _stage("task_failed")
        return False

    log(f"タスク開始: #{issue_num} {task_title} (累計失敗: {total_fails}/{MAX_FAIL_TOTAL})")
    notifier.notify("タスク開始", f"#{issue_num} {task_title}")

    # Issue 4: タスクをIN_PROGRESSに移動
    task_manager.move_to_in_progress(task, session_id)
    _commit_todo(git, f"chore: #{issue_num} IN_PROGRESS")

    # Issue本文を取得
    try:
        issue_body = github.get_issue_body(issue_num)
    except GitHubError:
        issue_body = ""

    # git stash + ブランチ作成
    stashed = False
    try:
        stashed = git.stash_if_dirty()
        git.create_branch(branch_name)
    except GitError as e:
        # ブランチが既存の場合はチェックアウト
        try:
            git.checkout(branch_name)
        except GitError:
            log(f"ERROR: ブランチ操作失敗: {e}")
            _stage("task_failed")
            return False

    # プロンプト構築
    prompt = build_prompt(issue_num, task_title, issue_body)

    # Claude用のallowedToolsリスト（実装+テスト+コミットに集中）
    allowed_tools = (
        "Read,Grep,Glob,Edit,Write,"
        "Bash(flutter *),Bash(dart *),Bash(git add*),Bash(git commit*),"
        "Bash(git status*),Bash(git diff*),Bash(git log*),Bash(ls*),Bash(mkdir*),"
        "Bash(cat*)"
    )

    # ClaudeRunner初期化
    runner = ClaudeRunner()

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

        # Claude実行
        _stage("claude_execute")
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
        claude_result = runner.run(cmd)
        claude_exit_code = claude_result.exit_code
        claude_output = claude_result.stdout
        timed_out = claude_result.timed_out

        log(f"Claude終了コード: {claude_exit_code}")

        # Claude出力をファイルに保存（デバッグ用）
        output_file = LOG_DIR / f"claude_output_{issue_num}_{retry_count}.txt"
        try:
            output_file.write_text(claude_output, encoding="utf-8")
            log(f"Claude出力保存: {output_file.name}")
        except OSError:
            pass

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

            notifier.notify("要確認", f"#{issue_num} {task_title}")
            duration = time.time() - start_time
            metrics.record(
                issue_number=issue_num, task_type=task.task_type, success=False,
                retries=retry_count, duration_seconds=duration,
                claude_exit_code=claude_exit_code,
                analyze_pass=False, test_pass=False,
                error_message="要確認事項あり",
            )
            try:
                _cleanup_branch(git, branch_name, stash_pop=stashed)
            except GitError as e:
                log(f"ERROR: ブランチクリーンアップ失敗: {e}")
                notifier.notify("ERROR", f"#{issue_num} クリーンアップ失敗: {e}")
            _stage("task_failed")
            return False

        # Claude実行失敗
        if claude_exit_code != 0:
            log(f"ERROR: Claude実行失敗 (exit: {claude_exit_code})")
            retry_count += 1
            if retry_count < MAX_RETRIES:
                log("リトライします...")
                retry_sleep(retry_count)
                continue
            report_manager.write_report(
                issue_num, task_title, "失敗",
                notes=f"Claude実行エラー (exit: {claude_exit_code})",
            )
            increment_fail_count(issue_num)

            notifier.notify("失敗", f"#{issue_num} {task_title}")
            duration = time.time() - start_time
            metrics.record(
                issue_number=issue_num, task_type=task.task_type, success=False,
                retries=retry_count, duration_seconds=duration,
                claude_exit_code=claude_exit_code,
                analyze_pass=False, test_pass=False,
                error_message=f"Claude exit {claude_exit_code}",
            )
            try:
                _cleanup_branch(git, branch_name, stash_pop=stashed)
            except GitError as e:
                log(f"ERROR: ブランチクリーンアップ失敗: {e}")
                notifier.notify("ERROR", f"#{issue_num} クリーンアップ失敗: {e}")
            _stage("task_failed")
            return False

        # コミット有無チェック
        commit_count = git.commit_count(branch_name)
        if commit_count == 0:
            log("WARN: コミットなし")
            retry_count += 1
            if retry_count < MAX_RETRIES:
                log("リトライします...")
                retry_sleep(retry_count)
                continue
            report_manager.write_report(
                issue_num, task_title, "失敗", changed_files="0件",
                notes="コミットなし",
            )
            increment_fail_count(issue_num)

            notifier.notify("失敗", f"#{issue_num} コミットなし")
            duration = time.time() - start_time
            metrics.record(
                issue_number=issue_num, task_type=task.task_type, success=False,
                retries=retry_count, duration_seconds=duration,
                claude_exit_code=claude_exit_code,
                analyze_pass=False, test_pass=False,
                error_message="コミットなし",
            )
            try:
                _cleanup_branch(git, branch_name, stash_pop=stashed)
            except GitError as e:
                log(f"ERROR: ブランチクリーンアップ失敗: {e}")
                notifier.notify("ERROR", f"#{issue_num} クリーンアップ失敗: {e}")
            _stage("task_failed")
            return False

        # --- 検証フェーズ ---
        _stage("flutter_analyze")
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

            notifier.notify("失敗", f"#{issue_num} analyze エラー")
            duration = time.time() - start_time
            metrics.record(
                issue_number=issue_num, task_type=task.task_type, success=False,
                retries=retry_count, duration_seconds=duration,
                claude_exit_code=claude_exit_code,
                analyze_pass=False, test_pass=False,
                error_message="flutter analyze失敗",
            )
            try:
                _cleanup_branch(git, branch_name, stash_pop=stashed)
            except GitError as e:
                log(f"ERROR: ブランチクリーンアップ失敗: {e}")
                notifier.notify("ERROR", f"#{issue_num} クリーンアップ失敗: {e}")
            _stage("task_failed")
            return False

        log("flutter analyze: OK")

        _stage("flutter_test")
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

            notifier.notify("失敗", f"#{issue_num} テスト失敗")
            duration = time.time() - start_time
            metrics.record(
                issue_number=issue_num, task_type=task.task_type, success=False,
                retries=retry_count, duration_seconds=duration,
                claude_exit_code=claude_exit_code,
                analyze_pass=True, test_pass=False,
                error_message="flutter test失敗",
            )
            try:
                _cleanup_branch(git, branch_name, stash_pop=stashed)
            except GitError as e:
                log(f"ERROR: ブランチクリーンアップ失敗: {e}")
                notifier.notify("ERROR", f"#{issue_num} クリーンアップ失敗: {e}")
            _stage("task_failed")
            return False

        test_pass_text = f"All {test_count} tests passed"
        log(f"検証成功: {test_pass_text}")

        # --- 成功：push + PR作成 ---
        changed_files = git.changed_files()
        claude_summary = claude_output[-4000:] if len(claude_output) > 4000 else claude_output

        _stage("git_push")
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

            notifier.notify("失敗", f"#{issue_num} git push失敗（ネットワーク確認要）")
            try:
                _cleanup_branch(git, branch_name, stash_pop=stashed)
            except GitError as cleanup_e:
                log(f"ERROR: ブランチクリーンアップ失敗: {cleanup_e}")
                notifier.notify("ERROR", f"#{issue_num} クリーンアップ失敗: {cleanup_e}")
            duration = time.time() - start_time
            metrics.record(
                issue_number=issue_num, task_type=task.task_type, success=False,
                retries=retry_count, duration_seconds=duration,
                claude_exit_code=claude_exit_code,
                analyze_pass=True, test_pass=True, test_count=test_count,
                error_message="git push失敗",
            )
            _stage("task_failed")
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

        _stage("pr_created")
        log(f"PR作成: #{pr_number}")

        # mainに戻してからTODO.mdを更新（ブランチ上で更新するとmain復帰時に失われる）
        try:
            _cleanup_branch(git, branch_name, delete=False, stash_pop=stashed)
        except GitError as e:
            log(f"ERROR: ブランチクリーンアップ失敗: {e}")
            notifier.notify("ERROR", f"#{issue_num} クリーンアップ失敗: {e}")
            _stage("task_failed")
            return False

        task_manager.move_to_done(task, pr_number)
        _commit_todo(git, f"chore: #{issue_num} DONE → PR #{pr_number}")
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
        _stage("task_complete")
        log(f"タスク完了: #{issue_num} → PR #{pr_number}")
        return True

    # whileが完走（全リトライ失敗）— ここには来ないはずだが安全策
    try:
        _cleanup_branch(git, branch_name, stash_pop=stashed)
    except GitError as e:
        log(f"ERROR: ブランチクリーンアップ失敗: {e}")
        notifier.notify("ERROR", f"クリーンアップ失敗: {e}")
    _stage("task_failed")
    return False
