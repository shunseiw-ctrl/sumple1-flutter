"""GitHubServiceのユニットテスト"""

import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.github_service import GitHubService, GitHubError


def make_completed_process(stdout="", stderr="", returncode=0):
    """CompletedProcessモックを生成"""
    return subprocess.CompletedProcess(
        args=[], returncode=returncode, stdout=stdout, stderr=stderr
    )


class TestGitHubService(unittest.TestCase):

    def setUp(self):
        self.gh = GitHubService(project_dir=Path("/tmp/test_project"))

    @patch("subprocess.run")
    def test_check_auth成功(self, mock_run):
        mock_run.return_value = make_completed_process(returncode=0)
        self.assertTrue(self.gh.check_auth())

    @patch("subprocess.run")
    def test_check_auth失敗(self, mock_run):
        mock_run.return_value = make_completed_process(returncode=1, stderr="not logged in")
        self.assertFalse(self.gh.check_auth())

    @patch("subprocess.run")
    def test_get_issue_body正常(self, mock_run):
        mock_run.return_value = make_completed_process(stdout="Issue本文です\n")
        body = self.gh.get_issue_body(123)
        self.assertEqual(body, "Issue本文です")

    @patch("subprocess.run")
    def test_get_issue_body失敗時GitHubError(self, mock_run):
        mock_run.return_value = make_completed_process(
            returncode=1, stderr="not found"
        )
        with self.assertRaises(GitHubError):
            self.gh.get_issue_body(999)

    @patch("subprocess.run")
    def test_create_prで番号抽出(self, mock_run):
        mock_run.return_value = make_completed_process(
            stdout="https://github.com/owner/repo/pull/42\n"
        )
        pr_num = self.gh.create_pr(
            title="テストPR",
            body="本文",
            branch="auto/1-test",
        )
        self.assertEqual(pr_num, 42)

    @patch("subprocess.run")
    def test_list_auto_issues空(self, mock_run):
        mock_run.return_value = make_completed_process(
            returncode=0, stdout="[]"
        )
        issues = self.gh.list_auto_issues()
        self.assertEqual(issues, [])

    @patch("subprocess.run")
    def test_list_auto_issuesのJSON解析(self, mock_run):
        mock_run.return_value = make_completed_process(
            returncode=0,
            stdout='[{"number":1,"title":"テスト","body":"本文"}]'
        )
        issues = self.gh.list_auto_issues()
        self.assertEqual(len(issues), 1)
        self.assertEqual(issues[0].number, 1)
        self.assertEqual(issues[0].title, "テスト")

    @patch("subprocess.run")
    def test_close_issue(self, mock_run):
        mock_run.return_value = make_completed_process()
        self.gh.close_issue(10)
        args = mock_run.call_args[0][0]
        self.assertIn("close", args)
        self.assertIn("10", args)

    @patch("subprocess.run")
    def test_add_label(self, mock_run):
        mock_run.return_value = make_completed_process()
        self.gh.add_label(10, "auto-dev")
        args = mock_run.call_args[0][0]
        self.assertIn("--add-label", args)
        self.assertIn("auto-dev", args)


if __name__ == "__main__":
    unittest.main()
