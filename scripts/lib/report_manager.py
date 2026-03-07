"""REPORT.md管理モジュール"""

import tempfile
from datetime import datetime
from pathlib import Path
from typing import Optional

from .config import REPORT_FILE, REPORT_MAX_ENTRIES


class ReportManager:
    """REPORT.mdへの結果記録・截頭"""

    HEADER = "# REPORT\n"

    def __init__(self, report_file: Path = REPORT_FILE):
        self.report_file = report_file

    def write_report(
        self,
        issue_number: int,
        title: str,
        status: str,
        changed_files: str = "-",
        test_result: str = "-",
        pr_number: Optional[int] = None,
        notes: str = "",
    ) -> None:
        """レポートエントリを先頭に追加"""
        now = datetime.now().strftime("%Y-%m-%d %H:%M")
        pr_text = f"#{pr_number}" if pr_number else "-"

        entry = (
            f"\n## {now} — #{issue_number} {title}\n"
            f"- **ステータス**: {status}\n"
            f"- **変更ファイル**: {changed_files}\n"
            f"- **テスト結果**: {test_result}\n"
            f"- **PR**: {pr_text}\n"
        )
        if notes:
            entry += f"- **課題**: {notes}\n"

        existing = self._read_content()
        # ヘッダーの後に新エントリを挿入
        if existing.startswith(self.HEADER):
            body = existing[len(self.HEADER):]
            new_content = self.HEADER + entry + body
        else:
            new_content = self.HEADER + entry + "\n" + existing

        self._write_content(new_content)
        self.truncate()

    def truncate(self, max_entries: int = REPORT_MAX_ENTRIES) -> None:
        """エントリ数がmax_entriesを超えたら古いものを削除"""
        content = self._read_content()
        # ## で始まる行でエントリを分割（ヘッダーの # REPORT は除外）
        parts = content.split("\n## ")
        if len(parts) <= 1:
            return

        header = parts[0]
        entries = parts[1:]

        if len(entries) <= max_entries:
            return

        # 最新max_entries件を保持
        kept = entries[:max_entries]
        new_content = header + "\n## " + "\n## ".join(kept)
        self._write_content(new_content)

    def _read_content(self) -> str:
        """REPORT.mdの内容を読み取る"""
        if not self.report_file.exists():
            return self.HEADER
        return self.report_file.read_text()

    def _write_content(self, content: str) -> None:
        """atomic write"""
        self.report_file.parent.mkdir(parents=True, exist_ok=True)
        fd, tmp_path = tempfile.mkstemp(
            dir=str(self.report_file.parent),
            prefix=".report_",
            suffix=".tmp",
        )
        try:
            with open(fd, "w") as f:
                f.write(content)
            Path(tmp_path).replace(self.report_file)
        except Exception:
            try:
                Path(tmp_path).unlink()
            except OSError:
                pass
            raise
