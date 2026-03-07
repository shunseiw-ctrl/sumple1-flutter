"""ReportManagerのユニットテスト"""

import tempfile
import unittest
from pathlib import Path

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.report_manager import ReportManager


class TestReportManager(unittest.TestCase):

    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.report_file = Path(self.tmpdir) / "REPORT.md"
        self.rm = ReportManager(self.report_file)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmpdir, ignore_errors=True)

    def test_empty_report_creates_header(self):
        self.rm.write_report(
            issue_number=1, title="test: テスト", status="成功",
        )
        content = self.report_file.read_text()
        self.assertTrue(content.startswith("# REPORT"))

    def test_write_report_prepends_entry(self):
        # 1件目
        self.rm.write_report(
            issue_number=1, title="test: 古いタスク", status="成功",
        )
        # 2件目
        self.rm.write_report(
            issue_number=2, title="fix: 新しいタスク", status="成功",
            pr_number=10,
        )
        content = self.report_file.read_text()
        # 2件目が先に出現する
        pos_new = content.index("#2")
        pos_old = content.index("#1")
        self.assertLess(pos_new, pos_old)

    def test_write_report_includes_all_fields(self):
        self.rm.write_report(
            issue_number=5,
            title="feat: 新機能追加",
            status="成功",
            changed_files="main.dart, home.dart",
            test_result="All 100 tests passed",
            pr_number=42,
            notes="特記事項なし",
        )
        content = self.report_file.read_text()
        self.assertIn("#5 feat: 新機能追加", content)
        self.assertIn("成功", content)
        self.assertIn("main.dart, home.dart", content)
        self.assertIn("All 100 tests passed", content)
        self.assertIn("#42", content)
        self.assertIn("特記事項なし", content)

    def test_truncate_report_keeps_max_entries(self):
        for i in range(10):
            self.rm.write_report(
                issue_number=i, title=f"test: タスク{i}", status="成功",
            )

        self.rm.truncate(max_entries=5)
        content = self.report_file.read_text()
        # 最新5件のみ残る（#9, #8, #7, #6, #5）
        self.assertIn("#9", content)
        self.assertIn("#5", content)
        self.assertNotIn("#4 test:", content)
        self.assertNotIn("#0 test:", content)

    def test_truncate_does_nothing_when_under_limit(self):
        self.rm.write_report(
            issue_number=1, title="test: テスト", status="成功",
        )
        content_before = self.report_file.read_text()
        self.rm.truncate(max_entries=50)
        content_after = self.report_file.read_text()
        self.assertEqual(content_before, content_after)

    def test_write_report_without_pr_shows_dash(self):
        self.rm.write_report(
            issue_number=1, title="test: テスト", status="失敗",
        )
        content = self.report_file.read_text()
        self.assertIn("**PR**: -", content)

    def test_write_report_without_notes_omits_field(self):
        self.rm.write_report(
            issue_number=1, title="test: テスト", status="成功",
        )
        content = self.report_file.read_text()
        self.assertNotIn("**課題**", content)


if __name__ == "__main__":
    unittest.main()
