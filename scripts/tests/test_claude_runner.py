"""ClaudeRunnerのユニットテスト"""

import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.claude_runner import ClaudeResult, ClaudeRunner


class TestClaudeResult(unittest.TestCase):

    def test_success_exit_code_0(self):
        r = ClaudeResult(exit_code=0, stdout="ok", stderr="", duration=1.0)
        self.assertTrue(r.success)

    def test_success_exit_code_nonzero(self):
        r = ClaudeResult(exit_code=1, stdout="", stderr="err", duration=1.0)
        self.assertFalse(r.success)

    def test_success_timed_out(self):
        r = ClaudeResult(exit_code=0, stdout="ok", stderr="", duration=1.0, timed_out=True)
        self.assertFalse(r.success)


class TestClaudeRunner(unittest.TestCase):

    def setUp(self):
        self.project_dir = Path("/tmp/test_project")
        self.runner = ClaudeRunner(
            project_dir=self.project_dir,
            timeout=30,
        )

    @patch("subprocess.Popen")
    def test_run_正常実行(self, mock_popen_cls):
        mock_proc = MagicMock()
        mock_proc.communicate.return_value = (b"output", b"")
        mock_proc.returncode = 0
        mock_popen_cls.return_value = mock_proc

        result = self.runner.run(["claude", "-p", "テスト"])

        self.assertEqual(result.exit_code, 0)
        self.assertEqual(result.stdout, "output")
        self.assertTrue(result.success)

    @patch("subprocess.Popen")
    def test_run_失敗時(self, mock_popen_cls):
        mock_proc = MagicMock()
        mock_proc.communicate.return_value = (b"", b"error occurred")
        mock_proc.returncode = 1
        mock_popen_cls.return_value = mock_proc

        result = self.runner.run(["claude", "-p", "テスト"])

        self.assertEqual(result.exit_code, 1)
        self.assertFalse(result.success)

    @patch("subprocess.Popen", side_effect=FileNotFoundError)
    def test_run_command_not_found(self, mock_popen_cls):
        result = self.runner.run(["claude", "-p", "テスト"])
        self.assertEqual(result.exit_code, 127)
        self.assertIn("command not found", result.stderr)

    @patch("subprocess.Popen")
    def test_cwdがproject_dirに設定される(self, mock_popen_cls):
        mock_proc = MagicMock()
        mock_proc.communicate.return_value = (b"", b"")
        mock_proc.returncode = 0
        mock_popen_cls.return_value = mock_proc

        self.runner.run(["claude", "-p", "テスト"])

        call_kwargs = mock_popen_cls.call_args[1]
        self.assertEqual(call_kwargs["cwd"], str(self.project_dir))

    def test_kill_processがOSErrorを握りつぶす(self):
        mock_proc = MagicMock()
        mock_proc.terminate.side_effect = OSError("No such process")
        # 例外が出ないことを確認
        ClaudeRunner._kill_process(mock_proc)


if __name__ == "__main__":
    unittest.main()
