"""通知モジュール（macOS/LINE Messaging API/Slack）"""

import json
import subprocess
import urllib.request

from .config import LINE_CHANNEL_TOKEN, LINE_USER_ID, SLACK_WEBHOOK_URL


class Notifier:
    """マルチチャネル通知"""

    def notify(self, title: str, message: str) -> None:
        """全チャネルに通知を送信（エラーは無視）"""
        self._macos_notify(title, message)
        self._line_notify(title, message)
        self._slack_notify(title, message)

    def _macos_notify(self, title: str, message: str) -> None:
        """macOS通知"""
        try:
            # AppleScript特殊文字をエスケープ
            safe_title = title.replace("\\", "\\\\").replace('"', '\\"')
            safe_msg = message.replace("\\", "\\\\").replace('"', '\\"')
            script = (
                f'display notification "{safe_msg}" '
                f'with title "ALBAWORK" subtitle "{safe_title}"'
            )
            subprocess.run(
                ["osascript", "-e", script],
                capture_output=True,
                timeout=10,
            )
        except Exception:
            pass

    def _line_notify(self, title: str, message: str) -> None:
        """LINE Messaging API push通知"""
        if not LINE_CHANNEL_TOKEN or not LINE_USER_ID:
            return

        try:
            url = "https://api.line.me/v2/bot/message/push"
            text = f"[ALBAWORK] {title}\n{message}"
            data = json.dumps({
                "to": LINE_USER_ID,
                "messages": [{"type": "text", "text": text}],
            }).encode("utf-8")

            req = urllib.request.Request(
                url,
                data=data,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {LINE_CHANNEL_TOKEN}",
                },
            )
            urllib.request.urlopen(req, timeout=10)
        except Exception:
            pass

    def _slack_notify(self, title: str, message: str) -> None:
        """Slack Webhook通知"""
        if not SLACK_WEBHOOK_URL:
            return

        try:
            data = json.dumps({
                "text": f"*[ALBAWORK] {title}*\n{message}",
            }).encode("utf-8")

            req = urllib.request.Request(
                SLACK_WEBHOOK_URL,
                data=data,
                headers={"Content-Type": "application/json"},
            )
            urllib.request.urlopen(req, timeout=10)
        except Exception:
            pass
