"""LockManagerのユニットテスト"""

import json
import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.lock_manager import LockManager, LockError


class TestLockManager(unittest.TestCase):

    def setUp(self):
        self.lock_file = Path("/tmp/test_lock_manager.lock")
        self._cleanup()

    def tearDown(self):
        self._cleanup()

    def _cleanup(self):
        try:
            self.lock_file.unlink()
        except FileNotFoundError:
            pass

    def test_ロック取得でPIDファイル作成(self):
        lm = LockManager(lock_file=self.lock_file)
        with lm:
            self.assertTrue(self.lock_file.exists())
            data = json.loads(self.lock_file.read_text())
            self.assertEqual(data["pid"], os.getpid())

    def test_コンテキスト終了でロック解放(self):
        lm = LockManager(lock_file=self.lock_file)
        with lm:
            self.assertTrue(self.lock_file.exists())
        self.assertFalse(self.lock_file.exists())

    def test_二重ロックでLockError(self):
        lm1 = LockManager(lock_file=self.lock_file)
        lm2 = LockManager(lock_file=self.lock_file)
        with lm1:
            with self.assertRaises(LockError):
                lm2.__enter__()

    def test_staleロックの自動解除(self):
        """存在しないPID(99999999)のロックは自動解除される"""
        self.lock_file.write_text(json.dumps({"pid": 99999999, "start_time": "", "timestamp": 0}))
        lm = LockManager(lock_file=self.lock_file)
        # staleロックがあっても取得できる
        with lm:
            data = json.loads(self.lock_file.read_text())
            self.assertEqual(data["pid"], os.getpid())

    def test_PID_0のロックファイルは無効(self):
        self.lock_file.write_text(json.dumps({"pid": 0, "start_time": "", "timestamp": 0}))
        lm = LockManager(lock_file=self.lock_file)
        self.assertFalse(lm._is_locked())

    def test_不正内容のロックファイルは無効(self):
        self.lock_file.write_text("not_a_number_nor_json")
        lm = LockManager(lock_file=self.lock_file)
        # _read_lock_dataがpid=0を返し、_is_lockedがFalseになる
        self.assertFalse(lm._is_locked())

    def test_ロックファイルなしはロックされていない(self):
        lm = LockManager(lock_file=self.lock_file)
        self.assertFalse(lm._is_locked())

    def test_自分自身のPIDは生存判定(self):
        self.assertTrue(LockManager._is_process_alive(os.getpid()))

    def test_存在しないPIDは死亡判定(self):
        self.assertFalse(LockManager._is_process_alive(99999999))

    def test_例外発生時もロック解放(self):
        lm = LockManager(lock_file=self.lock_file)
        with self.assertRaises(ValueError):
            with lm:
                self.assertTrue(self.lock_file.exists())
                raise ValueError("テスト例外")
        self.assertFalse(self.lock_file.exists())


if __name__ == "__main__":
    unittest.main()
