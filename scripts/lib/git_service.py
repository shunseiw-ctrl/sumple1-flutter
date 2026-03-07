"""Git操作モジュール"""

import subprocess
from pathlib import Path

from .config import PROJECT_DIR


class GitError(Exception):
    """Git操作エラー"""


class GitService:
    """Git操作ラッパー"""

    def __init__(self, project_dir: Path = PROJECT_DIR):
        self.project_dir = project_dir

    def _run(self, args: list, check: bool = True) -> subprocess.CompletedProcess:
        """gitコマンドを実行"""
        cmd = ["git"] + args
        result = subprocess.run(
            cmd,
            cwd=str(self.project_dir),
            capture_output=True,
            text=True,
        )
        if check and result.returncode != 0:
            raise GitError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
        return result

    def is_dirty(self) -> bool:
        """未コミットの変更があるか"""
        result = self._run(["status", "--porcelain"], check=False)
        return bool(result.stdout.strip())

    def stash_if_dirty(self) -> bool:
        """変更があればstash"""
        if self.is_dirty():
            self._run(["stash", "push", "-m", "auto_dev: 自動stash"])
            return True
        return False

    def stash_pop(self) -> None:
        """stashを復元"""
        self._run(["stash", "pop"], check=False)

    def current_branch(self) -> str:
        """現在のブランチ名"""
        result = self._run(["branch", "--show-current"])
        return result.stdout.strip()

    def checkout(self, branch: str) -> None:
        """ブランチを切り替え"""
        self._run(["checkout", branch])

    def create_branch(self, name: str) -> None:
        """mainから新ブランチを作成してチェックアウト"""
        # まずmainを最新にする
        self._run(["checkout", "main"])
        self._run(["pull", "origin", "main"], check=False)
        self._run(["checkout", "-b", name])

    def push(self, branch: str) -> None:
        """リモートにpush"""
        result = self._run(["push", "-u", "origin", branch], check=False)
        if result.returncode != 0:
            raise GitError(f"push failed: {result.stderr.strip()}")

    def reset_hard(self, ref: str = "HEAD") -> None:
        """ハードリセット"""
        self._run(["reset", "--hard", ref])

    def has_commits_on_branch(self, branch: str, base: str = "main") -> bool:
        """ブランチにbase以降のコミットがあるか"""
        result = self._run(
            ["log", f"{base}..{branch}", "--oneline"], check=False
        )
        return bool(result.stdout.strip())

    def commit_count(self, branch: str, base: str = "main") -> int:
        """ブランチのコミット数"""
        result = self._run(
            ["rev-list", "--count", f"{base}..{branch}"], check=False
        )
        try:
            return int(result.stdout.strip())
        except ValueError:
            return 0

    def changed_files(self, base: str = "main") -> str:
        """変更ファイル一覧"""
        result = self._run(
            ["diff", "--name-only", base], check=False
        )
        return result.stdout.strip()

    def delete_branch(self, branch: str) -> None:
        """ローカルブランチを削除"""
        self._run(["branch", "-D", branch], check=False)

    def branch_exists(self, branch: str) -> bool:
        """ブランチが存在するか"""
        result = self._run(
            ["rev-parse", "--verify", branch], check=False
        )
        return result.returncode == 0
