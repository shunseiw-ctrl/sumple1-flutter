"""PIDベースのロック管理モジュール"""

import json
import os
import subprocess
import time
from pathlib import Path
from typing import Optional

from .config import LOCK_FILE


class LockError(Exception):
    """ロック取得失敗"""


class LockManager:
    """コンテキストマネージャ方式のPIDロック"""

    def __init__(self, lock_file: Path = LOCK_FILE):
        self.lock_file = lock_file

    def __enter__(self):
        if self._is_locked():
            lock_data = self._read_lock_data()
            raise LockError(
                f"別のプロセスが実行中です (PID: {lock_data.get('pid', 0)})"
            )
        self._acquire()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self._release()
        return False

    def _acquire(self):
        """ロックファイルを作成（PID+起動時刻をJSON形式で書き込み）"""
        self.lock_file.parent.mkdir(parents=True, exist_ok=True)
        pid = os.getpid()
        lock_data = {
            "pid": pid,
            "start_time": self._get_process_start_time(pid) or "",
            "timestamp": time.time(),
        }
        self.lock_file.write_text(json.dumps(lock_data))

    def _release(self):
        """ロックファイルを削除"""
        try:
            self.lock_file.unlink()
        except FileNotFoundError:
            pass

    def _read_lock_data(self) -> dict:
        """ロックファイルからPID+起動時刻を読み取る（後方互換: 旧PIDのみ形式もサポート）"""
        try:
            content = self.lock_file.read_text().strip()
            # JSON形式を試行
            try:
                return json.loads(content)
            except json.JSONDecodeError:
                # 旧形式: PIDのみ
                pid = int(content)
                return {"pid": pid, "start_time": ""}
        except (FileNotFoundError, ValueError):
            return {"pid": 0, "start_time": ""}

    def _read_pid(self) -> int:
        """ロックファイルからPIDを読み取る（後方互換ラッパー）"""
        return self._read_lock_data().get("pid", 0)

    def _is_locked(self) -> bool:
        """ロックが有効かチェック（staleロック自動解除）"""
        if not self.lock_file.exists():
            return False
        lock_data = self._read_lock_data()
        pid = lock_data.get("pid", 0)
        if pid == 0:
            self._release()
            return False
        if not self._is_process_alive(pid):
            # Staleロックを削除
            self._release()
            return False
        # PIDが生存している場合、起動時刻も照合
        recorded_start = lock_data.get("start_time", "")
        if recorded_start:
            current_start = self._get_process_start_time(pid)
            if current_start and current_start != recorded_start:
                # PIDが再利用されている（別プロセス）→ staleロック
                self._release()
                return False
        return True

    @staticmethod
    def _is_process_alive(pid: int) -> bool:
        """プロセスが生存しているか確認"""
        try:
            os.kill(pid, 0)
            return True
        except (ProcessLookupError, PermissionError):
            return False
        except OSError:
            return False

    @staticmethod
    def _get_process_start_time(pid: int) -> Optional[str]:
        """プロセスの起動時刻を取得"""
        try:
            result = subprocess.run(
                ["ps", "-o", "lstart=", "-p", str(pid)],
                capture_output=True, text=True, timeout=5,
            )
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
        except (subprocess.TimeoutExpired, OSError):
            pass
        return None

    @classmethod
    def is_locked(cls, lock_file: Path = LOCK_FILE) -> bool:
        """外部からロック状態を確認"""
        return cls(lock_file)._is_locked()
