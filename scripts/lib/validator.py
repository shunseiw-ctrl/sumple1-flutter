"""flutter analyze/test検証モジュール"""

import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

from .config import PROJECT_DIR


@dataclass
class AnalyzeResult:
    """flutter analyze結果"""
    exit_code: int
    error_count: int
    warning_count: int
    output: str

    @property
    def passed(self) -> bool:
        return self.exit_code == 0 and self.error_count == 0


@dataclass
class TestResult:
    """flutter test結果"""
    exit_code: int
    total: int
    passed: int
    failed: int
    output: str

    @property
    def all_passed(self) -> bool:
        return self.exit_code == 0 and self.failed == 0


class Validator:
    """Flutterプロジェクトの検証"""

    def __init__(self, project_dir: Path = PROJECT_DIR):
        self.project_dir = project_dir

    def run_analyze(self) -> AnalyzeResult:
        """flutter analyzeを実行"""
        result = subprocess.run(
            ["flutter", "analyze"],
            cwd=str(self.project_dir),
            capture_output=True,
            text=True,
            timeout=300,  # 5分
        )

        error_count = 0
        warning_count = 0
        output = result.stdout + result.stderr

        # エラー数・警告数を出力から抽出
        # パターン例: "3 issues found. (2 errors and 1 warning)"
        match = re.search(r"(\d+)\s+error", output)
        if match:
            error_count = int(match.group(1))
        match = re.search(r"(\d+)\s+warning", output)
        if match:
            warning_count = int(match.group(1))

        # "No issues found!" の場合
        if "No issues found" in output:
            error_count = 0
            warning_count = 0

        return AnalyzeResult(
            exit_code=result.returncode,
            error_count=error_count,
            warning_count=warning_count,
            output=output,
        )

    def run_test(self) -> TestResult:
        """flutter testを実行"""
        result = subprocess.run(
            ["flutter", "test"],
            cwd=str(self.project_dir),
            capture_output=True,
            text=True,
            timeout=600,  # 10分
        )

        output = result.stdout + result.stderr
        total = 0
        passed = 0
        failed = 0

        # パターン例: "All 1105 tests passed!" / "00:45 +1100 -5: Some tests failed."
        match = re.search(r"All (\d+) tests passed", output)
        if match:
            total = int(match.group(1))
            passed = total
        else:
            # "+N -M" パターン
            match = re.search(r"\+(\d+)\s+-(\d+)", output)
            if match:
                passed = int(match.group(1))
                failed = int(match.group(2))
                total = passed + failed
            else:
                # "+N" のみ（全テストパス）
                match = re.search(r"\+(\d+)", output)
                if match:
                    passed = int(match.group(1))
                    total = passed

        return TestResult(
            exit_code=result.returncode,
            total=total,
            passed=passed,
            failed=failed,
            output=output,
        )

    def check_commits(self, branch: str, base: str = "main") -> int:
        """ブランチのコミット数を確認"""
        result = subprocess.run(
            ["git", "rev-list", "--count", f"{base}..{branch}"],
            cwd=str(self.project_dir),
            capture_output=True,
            text=True,
        )
        try:
            return int(result.stdout.strip())
        except ValueError:
            return 0
