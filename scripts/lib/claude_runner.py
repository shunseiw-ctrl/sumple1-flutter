"""claude -p 実行・タイムアウト・出力解析モジュール"""

import subprocess
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from .config import TASK_TIMEOUT, MAX_TURNS, PROJECT_DIR, SYSTEM_PROMPT_FILE


@dataclass
class ClaudeResult:
    """Claude実行結果"""
    exit_code: int
    stdout: str
    stderr: str
    duration: float
    needs_clarification: bool = False
    timed_out: bool = False

    @property
    def success(self) -> bool:
        return self.exit_code == 0 and not self.needs_clarification and not self.timed_out


class ClaudeRunner:
    """claude CLIのラッパー"""

    CLARIFICATION_MARKER = "要確認:"

    def __init__(
        self,
        project_dir: Path = PROJECT_DIR,
        system_prompt_file: Path = SYSTEM_PROMPT_FILE,
        timeout: int = TASK_TIMEOUT,
        max_turns: int = MAX_TURNS,
    ):
        self.project_dir = project_dir
        self.system_prompt_file = system_prompt_file
        self.timeout = timeout
        self.max_turns = max_turns

    def run(self, prompt: str, output_file: Optional[Path] = None) -> ClaudeResult:
        """claude -p を実行してタイムアウト管理"""
        cmd = self._build_command(prompt)
        start_time = time.time()
        timed_out = False

        try:
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                cwd=str(self.project_dir),
            )

            # タイムアウト用タイマー
            timer = threading.Timer(self.timeout, self._kill_process, args=[proc])
            timer.start()

            try:
                stdout_bytes, stderr_bytes = proc.communicate()
            finally:
                timer.cancel()

            duration = time.time() - start_time
            stdout = stdout_bytes.decode("utf-8", errors="replace")
            stderr = stderr_bytes.decode("utf-8", errors="replace")

            # タイムアウト判定
            if proc.returncode == -9 or proc.returncode == -15:
                timed_out = True

            # 「要確認:」検出
            needs_clarification = self.CLARIFICATION_MARKER in stdout

            result = ClaudeResult(
                exit_code=proc.returncode,
                stdout=stdout,
                stderr=stderr,
                duration=duration,
                needs_clarification=needs_clarification,
                timed_out=timed_out,
            )

            # 出力ファイルに保存
            if output_file:
                output_file.parent.mkdir(parents=True, exist_ok=True)
                output_file.write_text(
                    f"=== Claude Output ===\n{stdout}\n\n=== Stderr ===\n{stderr}\n"
                )

            return result

        except FileNotFoundError:
            duration = time.time() - start_time
            return ClaudeResult(
                exit_code=127,
                stdout="",
                stderr="claude: command not found",
                duration=duration,
            )

    def _build_command(self, prompt: str) -> list:
        """claudeコマンドを構築"""
        cmd = ["claude", "-p", "--verbose"]

        if self.system_prompt_file.exists():
            cmd.extend(["--system-prompt", self.system_prompt_file.read_text()])

        cmd.extend(["--max-turns", str(self.max_turns)])
        cmd.append(prompt)

        return cmd

    @staticmethod
    def _kill_process(proc: subprocess.Popen) -> None:
        """タイムアウト時のプロセス強制終了"""
        try:
            proc.terminate()
            # 5秒待ってまだ生きてたらkill
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
        except OSError:
            pass
