"""claude -p 実行・タイムアウト・出力解析モジュール"""

import subprocess
import threading
import time
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional

from .config import TASK_TIMEOUT, PROJECT_DIR


@dataclass
class ClaudeResult:
    """Claude実行結果"""
    exit_code: int
    stdout: str
    stderr: str
    duration: float
    timed_out: bool = False

    @property
    def success(self) -> bool:
        return self.exit_code == 0 and not self.timed_out


class ClaudeRunner:
    """claude CLIのラッパー"""

    def __init__(
        self,
        project_dir: Path = PROJECT_DIR,
        timeout: int = TASK_TIMEOUT,
    ):
        self.project_dir = project_dir
        self.timeout = timeout

    def run(self, cmd: List[str], output_file: Optional[Path] = None) -> ClaudeResult:
        """コマンドリストを受け取り、タイムアウト管理付きで実行"""
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

            result = ClaudeResult(
                exit_code=proc.returncode,
                stdout=stdout,
                stderr=stderr,
                duration=duration,
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
