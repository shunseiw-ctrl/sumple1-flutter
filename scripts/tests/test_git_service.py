"""GitServiceのユニットテスト（subprocess.runのモック）"""

import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock
import subprocess

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.git_service import GitService, GitError


def make_completed_process(stdout="", stderr="", returncode=0):
    """CompletedProcessモックを生成"""
    return subprocess.CompletedProcess(
        args=[], returncode=returncode, stdout=stdout, stderr=stderr
    )


class TestGitService(unittest.TestCase):

    def setUp(self):
        self.git = GitService(project_dir=Path("/tmp/test_project"))

    @patch("subprocess.run")
    def test_is_dirty_true(self, mock_run):
        mock_run.return_value = make_completed_process(stdout="M lib/main.dart\n")
        self.assertTrue(self.git.is_dirty())

    @patch("subprocess.run")
    def test_is_dirty_false(self, mock_run):
        mock_run.return_value = make_completed_process(stdout="")
        self.assertFalse(self.git.is_dirty())

    @patch("subprocess.run")
    def test_create_branch_calls_correct_commands(self, mock_run):
        mock_run.return_value = make_completed_process()
        self.git.create_branch("auto/123-test")

        # 呼び出し順: checkout main → pull → checkout -b
        calls = mock_run.call_args_list
        self.assertEqual(len(calls), 3)
        self.assertEqual(calls[0][0][0], ["git", "checkout", "main"])
        self.assertEqual(calls[1][0][0], ["git", "pull", "origin", "main"])
        self.assertEqual(calls[2][0][0], ["git", "checkout", "-b", "auto/123-test"])

    @patch("subprocess.run")
    def test_push_failure_raises_exception(self, mock_run):
        mock_run.return_value = make_completed_process(
            returncode=1, stderr="fatal: remote error"
        )
        with self.assertRaises(GitError):
            self.git.push("test-branch")

    @patch("subprocess.run")
    def test_push_success(self, mock_run):
        mock_run.return_value = make_completed_process()
        # 例外が出なければOK
        self.git.push("test-branch")

    @patch("subprocess.run")
    def test_stash_when_dirty(self, mock_run):
        mock_run.side_effect = [
            make_completed_process(stdout="M file.dart\n"),  # status --porcelain
            make_completed_process(),  # stash push
        ]
        result = self.git.stash_if_dirty()
        self.assertTrue(result)
        self.assertEqual(mock_run.call_count, 2)

    @patch("subprocess.run")
    def test_stash_when_clean(self, mock_run):
        mock_run.return_value = make_completed_process(stdout="")
        result = self.git.stash_if_dirty()
        self.assertFalse(result)

    @patch("subprocess.run")
    def test_current_branch(self, mock_run):
        mock_run.return_value = make_completed_process(stdout="auto/123-test\n")
        self.assertEqual(self.git.current_branch(), "auto/123-test")

    @patch("subprocess.run")
    def test_commit_count(self, mock_run):
        mock_run.return_value = make_completed_process(stdout="3\n")
        self.assertEqual(self.git.commit_count("auto/123"), 3)

    @patch("subprocess.run")
    def test_commit_count_empty(self, mock_run):
        mock_run.return_value = make_completed_process(stdout="0\n")
        self.assertEqual(self.git.commit_count("auto/123"), 0)

    @patch("subprocess.run")
    def test_has_commits_on_branch(self, mock_run):
        mock_run.return_value = make_completed_process(stdout="abc123 commit msg\n")
        self.assertTrue(self.git.has_commits_on_branch("auto/123"))

    @patch("subprocess.run")
    def test_changed_files(self, mock_run):
        mock_run.return_value = make_completed_process(
            stdout="lib/main.dart\nlib/home.dart\n"
        )
        self.assertEqual(self.git.changed_files(), "lib/main.dart\nlib/home.dart")

    @patch("subprocess.run")
    def test_reset_hard(self, mock_run):
        mock_run.return_value = make_completed_process()
        self.git.reset_hard("main")
        mock_run.assert_called_once()
        args = mock_run.call_args[0][0]
        self.assertEqual(args, ["git", "reset", "--hard", "main"])

    @patch("subprocess.run")
    def test_branch_exists_true(self, mock_run):
        mock_run.return_value = make_completed_process(returncode=0)
        self.assertTrue(self.git.branch_exists("main"))

    @patch("subprocess.run")
    def test_branch_exists_false(self, mock_run):
        mock_run.return_value = make_completed_process(returncode=1)
        self.assertFalse(self.git.branch_exists("nonexistent"))


if __name__ == "__main__":
    unittest.main()
