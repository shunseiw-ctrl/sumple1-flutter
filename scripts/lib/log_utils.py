"""ログユーティリティモジュール"""

import time
from datetime import datetime

from lib.config import LOG_DIR, LOG_RETENTION_DAYS


def timestamp() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M")


def log(message: str) -> None:
    """ログ出力"""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    line = f"[{timestamp()}] {message}"
    print(line, flush=True)
    try:
        with open(LOG_DIR / "auto_dev.log", "a") as f:
            f.write(line + "\n")
    except OSError:
        pass


def rotate_logs() -> None:
    """古いログファイルを削除（*.log + claude_output_*.txt）"""
    if not LOG_DIR.exists():
        return
    cutoff = time.time() - LOG_RETENTION_DAYS * 86400
    deleted = 0
    for pattern in ("*.log", "claude_output_*.txt"):
        for log_file in LOG_DIR.glob(pattern):
            try:
                if log_file.stat().st_mtime < cutoff:
                    log_file.unlink()
                    deleted += 1
            except OSError:
                pass
    log(f"ログローテーション完了（{LOG_RETENTION_DAYS}日以上前のログを{deleted}件削除）")
