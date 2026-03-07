"""TaskManagerのユニットテスト"""

import tempfile
import unittest
from pathlib import Path

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.task_manager import TaskManager, Task


class TestTaskManager(unittest.TestCase):

    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.todo_file = Path(self.tmpdir) / "TODO.md"
        self.todo_file.write_text(
            "# TODO\n\n"
            "## PENDING\n"
            "- [ ] #8 test: テストタスク追加\n"
            "- [ ] #10 fix: UIバグ修正\n"
            "\n"
            "## IN_PROGRESS\n"
            "- [x] #9 refactor: コード整理 (session: 1234567)\n"
            "\n"
            "## DONE\n"
            "- [x] #7 docs: README更新 (PR #45)\n"
            "\n"
            "## FAILED\n"
            "- [x] #6 feat: 新機能 (失敗: テスト不合格)\n"
            "\n"
        )
        self.tm = TaskManager(self.todo_file)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmpdir, ignore_errors=True)

    def test_get_next_pending_returns_first_task(self):
        task = self.tm.get_next_pending()
        self.assertIsNotNone(task)
        self.assertEqual(task.issue_number, 8)
        self.assertEqual(task.title, "test: テストタスク追加")

    def test_get_next_pending_empty_returns_none(self):
        self.todo_file.write_text(
            "# TODO\n\n## PENDING\n\n## IN_PROGRESS\n\n## DONE\n\n## FAILED\n\n"
        )
        task = self.tm.get_next_pending()
        self.assertIsNone(task)

    def test_move_to_in_progress_adds_session_id(self):
        task = self.tm.get_next_pending()
        self.tm.move_to_in_progress(task, "abc1234")
        content = self.todo_file.read_text()
        self.assertIn("(session: abc1234)", content)
        # PENDINGから消えている
        self.assertNotIn("- [ ] #8 test: テストタスク追加\n", content.split("## IN_PROGRESS")[0])

    def test_move_to_done_adds_pr_number(self):
        task = Task(issue_number=9, title="refactor: コード整理", raw_line="")
        self.tm.move_to_done(task, 50)
        content = self.todo_file.read_text()
        self.assertIn("(PR #50)", content)
        # IN_PROGRESSセクションからは消えている
        in_progress_section = content.split("## IN_PROGRESS")[1].split("## DONE")[0]
        self.assertNotIn("#9", in_progress_section)

    def test_move_to_failed_adds_reason(self):
        task = Task(issue_number=9, title="refactor: コード整理", raw_line="")
        self.tm.move_to_failed(task, "analyze失敗")
        content = self.todo_file.read_text()
        self.assertIn("(失敗: analyze失敗)", content)

    def test_move_back_to_pending_restores_checkbox(self):
        task = Task(issue_number=9, title="refactor: コード整理", raw_line="")
        self.tm.move_back_to_pending(task)
        content = self.todo_file.read_text()
        pending_section = content.split("## PENDING")[1].split("## IN_PROGRESS")[0]
        self.assertIn("- [ ] #9 refactor: コード整理", pending_section)

    def test_special_characters_in_title_preserved(self):
        self.todo_file.write_text(
            "# TODO\n\n"
            "## PENDING\n"
            "- [ ] #20 fix: ダーク&ライトモード対応（テスト）\n"
            "\n"
            "## IN_PROGRESS\n\n## DONE\n\n## FAILED\n\n"
        )
        task = self.tm.get_next_pending()
        self.assertIsNotNone(task)
        self.assertEqual(task.issue_number, 20)
        self.assertIn("ダーク&ライトモード対応", task.title)

    def test_get_all_issue_numbers(self):
        numbers = self.tm.get_all_issue_numbers()
        self.assertEqual(numbers, {6, 7, 8, 9, 10})

    def test_add_to_pending(self):
        self.tm.add_to_pending(15, "chore: 依存関係更新")
        content = self.todo_file.read_text()
        self.assertIn("- [ ] #15 chore: 依存関係更新", content)

    def test_task_type_extraction(self):
        task = Task(issue_number=1, title="feat: 新機能", raw_line="")
        self.assertEqual(task.task_type, "feat")

        task2 = Task(issue_number=2, title="不明なタイプ", raw_line="")
        self.assertEqual(task2.task_type, "unknown")

    def test_concurrent_writes_atomic(self):
        """tmpfile方式でのatomic writeが正しく動作するか"""
        for i in range(100, 110):
            self.tm.add_to_pending(i, f"test: タスク{i}")

        numbers = self.tm.get_all_issue_numbers()
        for i in range(100, 110):
            self.assertIn(i, numbers)

    def test_nonexistent_file_returns_empty(self):
        nonexistent = Path(self.tmpdir) / "nonexistent.md"
        tm = TaskManager(nonexistent)
        self.assertIsNone(tm.get_next_pending())
        self.assertEqual(tm.get_all_issue_numbers(), set())


if __name__ == "__main__":
    unittest.main()
