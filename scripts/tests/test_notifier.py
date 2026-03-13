"""Notifierのユニットテスト"""

import sys
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock, call

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.notifier import Notifier


class TestNotifierMacOS(unittest.TestCase):

    @patch("subprocess.run")
    def test_macOS通知がosascriptを呼ぶ(self, mock_run):
        n = Notifier()
        n._macos_notify("タイトル", "メッセージ")
        mock_run.assert_called_once()
        args = mock_run.call_args[0][0]
        self.assertEqual(args[0], "osascript")
        self.assertEqual(args[1], "-e")

    @patch("subprocess.run")
    def test_ダブルクォートがエスケープされる(self, mock_run):
        n = Notifier()
        n._macos_notify('テスト"タイトル', 'テスト"メッセージ')
        mock_run.assert_called_once()
        script = mock_run.call_args[0][0][2]
        self.assertIn('\\"', script)
        self.assertNotIn('""', script)

    @patch("subprocess.run", side_effect=Exception("テスト例外"))
    def test_例外を握りつぶす(self, mock_run):
        n = Notifier()
        # 例外が出ないことを確認
        n._macos_notify("title", "msg")


class TestNotifierLINE(unittest.TestCase):

    @patch("lib.notifier.LINE_CHANNEL_TOKEN", "")
    @patch("lib.notifier.LINE_USER_ID", "")
    def test_LINEトークンなしでスキップ(self):
        n = Notifier()
        # urlopenが呼ばれないことを確認
        with patch("urllib.request.urlopen") as mock_urlopen:
            n._line_notify("title", "msg")
            mock_urlopen.assert_not_called()


class TestNotifierSlack(unittest.TestCase):

    @patch("lib.notifier.SLACK_WEBHOOK_URL", "")
    def test_SlackURLなしでスキップ(self):
        n = Notifier()
        with patch("urllib.request.urlopen") as mock_urlopen:
            n._slack_notify("title", "msg")
            mock_urlopen.assert_not_called()


class TestNotifierNotify(unittest.TestCase):

    @patch.object(Notifier, "_slack_notify")
    @patch.object(Notifier, "_line_notify")
    @patch.object(Notifier, "_macos_notify")
    def test_notifyが全チャネルを呼ぶ(self, mock_macos, mock_line, mock_slack):
        n = Notifier()
        n.notify("title", "msg")
        mock_macos.assert_called_once_with("title", "msg")
        mock_line.assert_called_once_with("title", "msg")
        mock_slack.assert_called_once_with("title", "msg")


if __name__ == "__main__":
    unittest.main()
