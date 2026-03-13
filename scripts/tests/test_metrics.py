"""MetricsManagerのユニットテスト"""

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.metrics import MetricsManager


class TestMetricsManager(unittest.TestCase):

    def setUp(self):
        self.tmp_dir = tempfile.mkdtemp()
        self.metrics_file = Path(self.tmp_dir) / "metrics.json"
        self.mm = MetricsManager(metrics_file=self.metrics_file)

    def tearDown(self):
        try:
            self.metrics_file.unlink()
        except FileNotFoundError:
            pass

    def _record_sample(self, issue=1, success=True, task_type="test", error_message=""):
        self.mm.record(
            issue_number=issue,
            task_type=task_type,
            success=success,
            retries=0,
            duration_seconds=60.0,
            claude_exit_code=0 if success else 1,
            analyze_pass=success,
            test_pass=success,
            test_count=10,
            error_message=error_message,
        )

    def test_初回recordでファイル作成(self):
        self.assertFalse(self.metrics_file.exists())
        self._record_sample()
        self.assertTrue(self.metrics_file.exists())

    def test_複数recordで追加(self):
        self._record_sample(issue=1)
        self._record_sample(issue=2)
        data = json.loads(self.metrics_file.read_text())
        self.assertEqual(len(data["runs"]), 2)

    def test_成功率計算(self):
        self._record_sample(issue=1, success=True)
        self._record_sample(issue=2, success=False)
        rate = self.mm.get_success_rate()
        self.assertAlmostEqual(rate, 0.5)

    def test_タイプ別集計(self):
        self._record_sample(issue=1, task_type="feat", success=True)
        self._record_sample(issue=2, task_type="feat", success=False)
        self._record_sample(issue=3, task_type="fix", success=True)
        summary = self.mm.get_summary()
        by_type = summary["by_type"]
        self.assertEqual(by_type["feat"]["runs"], 2)
        self.assertEqual(by_type["feat"]["successes"], 1)
        self.assertAlmostEqual(by_type["feat"]["success_rate"], 0.5)
        self.assertEqual(by_type["fix"]["runs"], 1)

    def test_エラーメッセージ記録(self):
        self._record_sample(issue=1, success=False, error_message="テストエラー")
        data = json.loads(self.metrics_file.read_text())
        self.assertEqual(data["runs"][0]["error_message"], "テストエラー")

    def test_空ファイルでデフォルト値(self):
        self.metrics_file.parent.mkdir(parents=True, exist_ok=True)
        self.metrics_file.write_text("")
        rate = self.mm.get_success_rate()
        self.assertEqual(rate, 0.0)

    def test_壊れたJSONでデフォルト値(self):
        self.metrics_file.parent.mkdir(parents=True, exist_ok=True)
        self.metrics_file.write_text("{broken json")
        rate = self.mm.get_success_rate()
        self.assertEqual(rate, 0.0)


if __name__ == "__main__":
    unittest.main()
