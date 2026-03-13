"""プロンプト構築モジュール"""

import re

from lib.config import TASK_PROMPT_TEMPLATE


def build_prompt(issue_num: int, task_title: str, issue_body: str) -> str:
    """Claude用プロンプトを構築"""
    body_content = issue_body or "（Issue本文なし。タスクタイトルから判断して実装してください）"

    if TASK_PROMPT_TEMPLATE.exists():
        template = TASK_PROMPT_TEMPLATE.read_text()
        prompt = template.replace("{{ISSUE_NUM}}", str(issue_num))
        prompt = prompt.replace("{{TASK_TITLE}}", task_title)
        prompt = prompt.replace("{{ISSUE_BODY}}", body_content)
        return prompt

    return f"""以下のタスクを実装してください。
#{issue_num} {task_title}
{body_content}"""


def make_branch_name(issue_num: int, task_title: str) -> str:
    """ブランチ名を生成"""
    safe = re.sub(r"[^a-zA-Z0-9-]", "-", task_title.replace(" ", "-").replace(":", "-"))
    safe = re.sub(r"-+", "-", safe).strip("-")[:40]
    return f"auto/{issue_num}-{safe}"
