"""TODO.md状態管理モジュール

TODO.mdのフォーマット:
```
# TODO

## PENDING
- [ ] #8 test: テストタスク

## IN_PROGRESS
- [ ] #9 fix: バグ修正 (session: abc123)

## DONE
- [x] #7 refactor: コード整理 (PR #45)

## FAILED
- [x] #6 feat: 新機能 (失敗: テスト不合格)
```
"""

import re
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from .config import TODO_FILE


@dataclass
class Task:
    """TODO.mdのタスク"""
    issue_number: int
    title: str
    raw_line: str

    @property
    def task_type(self) -> str:
        """タスクタイプ（feat/fix/test等）をタイトルから抽出"""
        match = re.match(r"^(feat|fix|test|refactor|chore|docs):", self.title)
        return match.group(1) if match else "unknown"


class TaskManager:
    """TODO.mdの状態管理"""

    SECTION_PENDING = "## PENDING"
    SECTION_IN_PROGRESS = "## IN_PROGRESS"
    SECTION_DONE = "## DONE"
    SECTION_FAILED = "## FAILED"
    SECTIONS = [SECTION_PENDING, SECTION_IN_PROGRESS, SECTION_DONE, SECTION_FAILED]

    # タスク行のパターン: - [ ] #123 タイトル または - [x] #123 タイトル (...)
    TASK_PATTERN = re.compile(r"^- \[[ x]\] #(\d+)\s+(.+?)(?:\s+\(.*\))?$")

    def __init__(self, todo_file: Path = TODO_FILE):
        self.todo_file = todo_file

    def get_next_pending(self) -> Optional[Task]:
        """PENDINGセクションの先頭タスクを取得"""
        sections = self._read_sections()
        for line in sections.get(self.SECTION_PENDING, []):
            task = self._parse_task_line(line)
            if task:
                return task
        return None

    def get_all_issue_numbers(self) -> set:
        """全セクションのIssue番号を取得"""
        numbers = set()
        sections = self._read_sections()
        for lines in sections.values():
            for line in lines:
                task = self._parse_task_line(line)
                if task:
                    numbers.add(task.issue_number)
        return numbers

    def move_to_in_progress(self, task: Task, session_id: str) -> None:
        """PENDING → IN_PROGRESS"""
        new_line = f"- [ ] #{task.issue_number} {task.title} (session: {session_id})"
        self._move_task(task, self.SECTION_PENDING, self.SECTION_IN_PROGRESS, new_line)

    def move_to_done(self, task: Task, pr_number: int) -> None:
        """IN_PROGRESS → DONE"""
        new_line = f"- [x] #{task.issue_number} {task.title} (PR #{pr_number})"
        self._move_task(task, self.SECTION_IN_PROGRESS, self.SECTION_DONE, new_line)

    def move_to_failed(self, task: Task, reason: str) -> None:
        """IN_PROGRESS → FAILED"""
        new_line = f"- [x] #{task.issue_number} {task.title} (失敗: {reason})"
        self._move_task(task, self.SECTION_IN_PROGRESS, self.SECTION_FAILED, new_line)

    def move_back_to_pending(self, task: Task) -> None:
        """IN_PROGRESS → PENDING（リトライ用）"""
        new_line = f"- [ ] #{task.issue_number} {task.title}"
        self._move_task(task, self.SECTION_IN_PROGRESS, self.SECTION_PENDING, new_line)

    def add_to_pending(self, issue_number: int, title: str) -> None:
        """PENDINGセクションにタスクを追加"""
        sections = self._read_sections()
        pending = sections.get(self.SECTION_PENDING, [])
        new_line = f"- [ ] #{issue_number} {title}"
        pending.append(new_line)
        sections[self.SECTION_PENDING] = pending
        self._write_sections(sections)

    def _move_task(self, task: Task, from_section: str, to_section: str, new_line: str) -> None:
        """タスクをセクション間で移動"""
        sections = self._read_sections()

        # from_sectionからタスクを削除
        from_lines = sections.get(from_section, [])
        sections[from_section] = [
            line for line in from_lines
            if not self._matches_task(line, task.issue_number)
        ]

        # to_sectionにタスクを追加
        to_lines = sections.get(to_section, [])
        to_lines.append(new_line)
        sections[to_section] = to_lines

        self._write_sections(sections)

    def _matches_task(self, line: str, issue_number: int) -> bool:
        """行が指定Issue番号のタスクか判定"""
        parsed = self._parse_task_line(line)
        return parsed is not None and parsed.issue_number == issue_number

    def _parse_task_line(self, line: str) -> Optional[Task]:
        """タスク行をパース"""
        line = line.strip()
        # 基本パターン: - [ ] #123 タイトル (オプションの括弧)
        match = re.match(r"^- \[[ x]\] #(\d+)\s+(.+?)(?:\s+\((?:session:|PR #|失敗:).*\))?$", line)
        if match:
            return Task(
                issue_number=int(match.group(1)),
                title=match.group(2).strip(),
                raw_line=line,
            )
        # シンプルパターン（括弧なし）
        match = re.match(r"^- \[[ x]\] #(\d+)\s+(.+)$", line)
        if match:
            return Task(
                issue_number=int(match.group(1)),
                title=match.group(2).strip(),
                raw_line=line,
            )
        return None

    def _read_sections(self) -> dict:
        """TODO.mdをセクション別に読み取る"""
        sections = {s: [] for s in self.SECTIONS}
        current_section = None

        if not self.todo_file.exists():
            return sections

        for line in self.todo_file.read_text().splitlines():
            stripped = line.strip()
            if stripped in self.SECTIONS:
                current_section = stripped
            elif current_section and stripped:
                sections[current_section].append(stripped)

        return sections

    def _write_sections(self, sections: dict) -> None:
        """セクションをTODO.mdにatomic write"""
        lines = ["# TODO", ""]
        for section in self.SECTIONS:
            lines.append(section)
            for task_line in sections.get(section, []):
                lines.append(task_line)
            lines.append("")

        content = "\n".join(lines)

        # atomic write: tmpfileに書いてからmv
        self.todo_file.parent.mkdir(parents=True, exist_ok=True)
        fd, tmp_path = tempfile.mkstemp(
            dir=str(self.todo_file.parent),
            prefix=".todo_",
            suffix=".tmp",
        )
        try:
            with open(fd, "w") as f:
                f.write(content)
            Path(tmp_path).replace(self.todo_file)
        except Exception:
            try:
                Path(tmp_path).unlink()
            except OSError:
                pass
            raise
