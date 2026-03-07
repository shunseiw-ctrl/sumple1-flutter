"""PIDベースのロック管理モジュール"""

import os
import signal
from pathlib import Path

from .config import LOCK_FILE


class LockError(Exception):
    """ロック取得失敗"""


class LockManager:
    """コンテキストマネージャ方式のPIDロック"""

    def __init__(self, lock_file: Path = LOCK_FILE):
        self.lock_file = lock_file

    def __enter__(self):
        if self._is_locked():
            raise LockError(
                f"別のプロセスが実行中です (PID: {self._read_pid()})"
            )
        self._acquire()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self._release()
        return False

    def _acquire(self):
        """ロックファイルを作成"""
        self.lock_file.parent.mkdir(parents=True, exist_ok=True)
        self.lock_file.write_text(str(os.getpid()))

    def _release(self):
        """ロックファイルを削除"""
        try:
            self.lock_file.unlink()
        except FileNotFoundError:
            pass

    def _read_pid(self) -> int:
        """ロックファイルからPIDを読み取る"""
        try:
            return int(self.lock_file.read_text().strip())
        except (FileNotFoundError, ValueError):
            return 0

    def _is_locked(self) -> bool:
        """ロックが有効かチェック（staleロック自動解除）"""
        if not self.lock_file.exists():
            return False
        pid = self._read_pid()
        if pid == 0:
            self._release()
            return False
        if not self._is_process_alive(pid):
            # Staleロックを削除
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

    @classmethod
    def is_locked(cls, lock_file: Path = LOCK_FILE) -> bool:
        """外部からロック状態を確認"""
        return cls(lock_file)._is_locked()
