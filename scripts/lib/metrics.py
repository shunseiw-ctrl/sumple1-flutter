"""成功率・コスト計測モジュール"""

import json
import os
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Optional

from .config import METRICS_FILE


class MetricsManager:
    """実行メトリクスの記録・集計"""

    def __init__(self, metrics_file: Path = METRICS_FILE):
        self.metrics_file = metrics_file

    def record(
        self,
        issue_number: int,
        task_type: str,
        success: bool,
        retries: int,
        duration_seconds: float,
        claude_exit_code: int,
        analyze_pass: bool,
        test_pass: bool,
        test_count: int = 0,
        pr_number: Optional[int] = None,
        auto_merged: bool = False,
        error_message: str = "",
    ) -> None:
        """実行結果を記録"""
        data = self._load()

        run_entry = {
            "timestamp": datetime.now().isoformat(timespec="seconds"),
            "issue_number": issue_number,
            "task_type": task_type,
            "success": success,
            "retries": retries,
            "duration_seconds": round(duration_seconds, 1),
            "claude_exit_code": claude_exit_code,
            "analyze_pass": analyze_pass,
            "test_pass": test_pass,
            "test_count": test_count,
            "pr_number": pr_number,
            "auto_merged": auto_merged,
        }
        if error_message:
            run_entry["error_message"] = error_message

        data["runs"].append(run_entry)
        data["summary"] = self._compute_summary(data["runs"])

        self._save(data)

    def get_success_rate(self) -> float:
        """全体成功率"""
        data = self._load()
        return data.get("summary", {}).get("success_rate", 0.0)

    def get_daily_summary(self) -> dict:
        """日次サマリー"""
        data = self._load()
        today = datetime.now().strftime("%Y-%m-%d")

        today_runs = [
            r for r in data.get("runs", [])
            if r["timestamp"].startswith(today)
        ]

        if not today_runs:
            return {"date": today, "runs": 0, "successes": 0, "failures": 0}

        successes = sum(1 for r in today_runs if r["success"])
        return {
            "date": today,
            "runs": len(today_runs),
            "successes": successes,
            "failures": len(today_runs) - successes,
            "success_rate": round(successes / len(today_runs), 2) if today_runs else 0,
            "avg_duration": round(
                sum(r["duration_seconds"] for r in today_runs) / len(today_runs), 1
            ),
        }

    def get_summary(self) -> dict:
        """全体サマリー"""
        data = self._load()
        return data.get("summary", {})

    def _compute_summary(self, runs: list) -> dict:
        """サマリーを計算"""
        if not runs:
            return {}

        total = len(runs)
        successes = sum(1 for r in runs if r["success"])
        failures = total - successes

        # タイプ別集計
        by_type = {}
        for run in runs:
            t = run.get("task_type", "unknown")
            if t not in by_type:
                by_type[t] = {"runs": 0, "successes": 0}
            by_type[t]["runs"] += 1
            if run["success"]:
                by_type[t]["successes"] += 1

        for t, stats in by_type.items():
            stats["success_rate"] = round(
                stats["successes"] / stats["runs"], 2
            ) if stats["runs"] > 0 else 0

        durations = [r["duration_seconds"] for r in runs]

        return {
            "total_runs": total,
            "successes": successes,
            "failures": failures,
            "success_rate": round(successes / total, 2) if total > 0 else 0,
            "avg_duration_seconds": round(sum(durations) / len(durations), 1),
            "by_type": by_type,
        }

    def _load(self) -> dict:
        """メトリクスファイルを読み込む"""
        if not self.metrics_file.exists():
            return {"runs": [], "summary": {}}
        try:
            return json.loads(self.metrics_file.read_text())
        except (json.JSONDecodeError, OSError):
            return {"runs": [], "summary": {}}

    def _save(self, data: dict) -> None:
        """メトリクスファイルにアトミック書き込み"""
        self.metrics_file.parent.mkdir(parents=True, exist_ok=True)
        fd, tmp_path = tempfile.mkstemp(
            dir=str(self.metrics_file.parent), suffix=".tmp"
        )
        try:
            with os.fdopen(fd, "w") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            Path(tmp_path).replace(self.metrics_file)
        except BaseException:
            try:
                Path(tmp_path).unlink()
            except OSError:
                pass
            raise
