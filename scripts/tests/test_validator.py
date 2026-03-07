"""Validatorのユニットテスト"""

import unittest
from pathlib import Path
from unittest.mock import patch
import subprocess

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.validator import Validator, AnalyzeResult, TestResult


def make_completed_process(stdout="", stderr="", returncode=0):
    return subprocess.CompletedProcess(
        args=[], returncode=returncode, stdout=stdout, stderr=stderr
    )


class TestValidator(unittest.TestCase):

    def setUp(self):
        self.validator = Validator(project_dir=Path("/tmp/test_project"))

    @patch("subprocess.run")
    def test_analyze_pass_returns_zero_errors(self, mock_run):
        mock_run.return_value = make_completed_process(
            stdout="Analyzing project...\nNo issues found!\n",
            returncode=0,
        )
        result = self.validator.run_analyze()
        self.assertTrue(result.passed)
        self.assertEqual(result.error_count, 0)
        self.assertEqual(result.exit_code, 0)

    @patch("subprocess.run")
    def test_analyze_fail_returns_nonzero(self, mock_run):
        mock_run.return_value = make_completed_process(
            stdout="Analyzing project...\n3 issues found. (2 errors and 1 warning)\n",
            returncode=1,
        )
        result = self.validator.run_analyze()
        self.assertFalse(result.passed)
        self.assertEqual(result.error_count, 2)
        self.assertEqual(result.warning_count, 1)

    @patch("subprocess.run")
    def test_analyze_warnings_only_still_passes(self, mock_run):
        mock_run.return_value = make_completed_process(
            stdout="Analyzing project...\n1 issue found. (1 warning)\n",
            returncode=0,
        )
        result = self.validator.run_analyze()
        self.assertTrue(result.passed)
        self.assertEqual(result.error_count, 0)
        self.assertEqual(result.warning_count, 1)

    @patch("subprocess.run")
    def test_test_extracts_count_all_passed(self, mock_run):
        mock_run.return_value = make_completed_process(
            stdout="00:45 +1105: All tests passed!\nAll 1105 tests passed!\n",
            returncode=0,
        )
        result = self.validator.run_test()
        self.assertTrue(result.all_passed)
        self.assertEqual(result.total, 1105)
        self.assertEqual(result.passed, 1105)
        self.assertEqual(result.failed, 0)

    @patch("subprocess.run")
    def test_test_extracts_count_with_failures(self, mock_run):
        mock_run.return_value = make_completed_process(
            stdout="00:45 +1100 -5: Some tests failed.\n",
            returncode=1,
        )
        result = self.validator.run_test()
        self.assertFalse(result.all_passed)
        self.assertEqual(result.total, 1105)
        self.assertEqual(result.passed, 1100)
        self.assertEqual(result.failed, 5)

    @patch("subprocess.run")
    def test_test_passed_only_pattern(self, mock_run):
        mock_run.return_value = make_completed_process(
            stdout="00:30 +500: All tests passed!\n",
            returncode=0,
        )
        result = self.validator.run_test()
        self.assertTrue(result.all_passed)
        self.assertEqual(result.passed, 500)

    @patch("subprocess.run")
    def test_check_commits(self, mock_run):
        mock_run.return_value = make_completed_process(stdout="5\n")
        count = self.validator.check_commits("auto/123")
        self.assertEqual(count, 5)

    @patch("subprocess.run")
    def test_check_commits_no_commits(self, mock_run):
        mock_run.return_value = make_completed_process(stdout="0\n")
        count = self.validator.check_commits("auto/123")
        self.assertEqual(count, 0)


class TestAnalyzeResult(unittest.TestCase):

    def test_passed_with_zero_errors(self):
        r = AnalyzeResult(exit_code=0, error_count=0, warning_count=0, output="")
        self.assertTrue(r.passed)

    def test_not_passed_with_errors(self):
        r = AnalyzeResult(exit_code=0, error_count=1, warning_count=0, output="")
        self.assertFalse(r.passed)

    def test_not_passed_with_nonzero_exit(self):
        r = AnalyzeResult(exit_code=1, error_count=0, warning_count=0, output="")
        self.assertFalse(r.passed)


class TestTestResult(unittest.TestCase):

    def test_all_passed(self):
        r = TestResult(exit_code=0, total=100, passed=100, failed=0, output="")
        self.assertTrue(r.all_passed)

    def test_not_all_passed(self):
        r = TestResult(exit_code=1, total=100, passed=95, failed=5, output="")
        self.assertFalse(r.all_passed)


if __name__ == "__main__":
    unittest.main()
