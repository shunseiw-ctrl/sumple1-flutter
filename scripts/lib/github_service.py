"""GitHub API操作モジュール（gh CLIラッパー）"""

import json
import subprocess
from dataclasses import dataclass
from pathlib import Path

from .config import PROJECT_DIR


@dataclass
class Issue:
    """GitHub Issue"""
    number: int
    title: str
    body: str


class GitHubError(Exception):
    """GitHub操作エラー"""


class GitHubService:
    """gh CLI操作"""

    def __init__(self, project_dir: Path = PROJECT_DIR):
        self.project_dir = project_dir

    def _run(self, args: list, check: bool = True) -> subprocess.CompletedProcess:
        """ghコマンドを実行"""
        cmd = ["gh"] + args
        result = subprocess.run(
            cmd,
            cwd=str(self.project_dir),
            capture_output=True,
            text=True,
        )
        if check and result.returncode != 0:
            raise GitHubError(f"gh {' '.join(args)} failed: {result.stderr.strip()}")
        return result

    def check_auth(self) -> bool:
        """GitHub CLI認証確認"""
        result = self._run(["auth", "status"], check=False)
        return result.returncode == 0

    def get_issue_body(self, number: int) -> str:
        """Issue本文を取得"""
        result = self._run([
            "issue", "view", str(number),
            "--json", "body",
            "--jq", ".body",
        ])
        return result.stdout.strip()

    def list_auto_issues(self) -> list:
        """label:auto のオープンIssueを取得"""
        result = self._run([
            "issue", "list",
            "--label", "auto",
            "--state", "open",
            "--json", "number,title,body",
            "--limit", "50",
        ], check=False)

        if result.returncode != 0 or not result.stdout.strip():
            return []

        try:
            issues_data = json.loads(result.stdout)
        except json.JSONDecodeError:
            return []

        return [
            Issue(
                number=item["number"],
                title=item["title"],
                body=item.get("body", ""),
            )
            for item in issues_data
        ]

    def create_pr(
        self,
        title: str,
        body: str,
        branch: str,
        base: str = "main",
    ) -> int:
        """PR作成してPR番号を返す"""
        # HEREDOC区切りの衝突を避けるためタイムスタンプ使用
        result = self._run([
            "pr", "create",
            "--title", title,
            "--body", body,
            "--head", branch,
            "--base", base,
            "--label", "auto-dev",
        ])

        # PR番号を出力から抽出
        output = result.stdout.strip()
        # 出力例: https://github.com/owner/repo/pull/123
        for part in output.split("/"):
            try:
                return int(part)
            except ValueError:
                continue

        # フォールバック: PRリストから取得
        return self._get_pr_number(branch)

    def _get_pr_number(self, branch: str) -> int:
        """ブランチのPR番号を取得"""
        result = self._run([
            "pr", "view", branch,
            "--json", "number",
            "--jq", ".number",
        ], check=False)

        try:
            return int(result.stdout.strip())
        except ValueError:
            return 0

    def add_label(self, issue_number: int, label: str) -> None:
        """Issueにラベルを追加"""
        self._run([
            "issue", "edit", str(issue_number),
            "--add-label", label,
        ], check=False)

    def close_issue(self, issue_number: int) -> None:
        """Issueをクローズ"""
        self._run([
            "issue", "close", str(issue_number),
        ], check=False)
