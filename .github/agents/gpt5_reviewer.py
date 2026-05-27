#!/usr/bin/env python3
"""Copilot PR reviewer — posts a structured review as a PR comment.

Loaded by .github/workflows/dual-review.yml. Uses gpt-5-mini (cheap)
for the review pass via the GitHub Copilot API.

Env:
    GH_TOKEN    required (workflow's GITHUB_TOKEN is fine)
    PR_NUMBER   required
    PR_REPO     required (e.g. "ClawfficeOrg/godotty")
"""

from __future__ import annotations

import json
import os
import pathlib
import subprocess
import sys
import textwrap
import urllib.request

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
SKILL_PATH = REPO_ROOT / ".github" / "skills" / "review" / "dual-review" / "SKILL.md"
AGENTS_PATH = REPO_ROOT / "AGENTS.md"

COPILOT_API = "https://api.githubcopilot.com/chat/completions"
REVIEW_MODEL = "gpt-5-mini"


def _required_env(name: str) -> str:
    val = os.environ.get(name)
    if not val:
        print(f"reviewer: missing required env var {name}; skipping")
        sys.exit(0)
    return val


def _git_diff_against_base() -> str:
    try:
        base = subprocess.check_output(
            ["git", "merge-base", "origin/master", "HEAD"], cwd=REPO_ROOT, text=True
        ).strip()
        diff = subprocess.check_output(
            ["git", "diff", base, "HEAD"], cwd=REPO_ROOT, text=True
        )
    except subprocess.CalledProcessError as exc:
        print(f"reviewer: git diff failed: {exc}")
        return ""
    if len(diff) > 200_000:
        diff = diff[:200_000] + "\n\n... (diff truncated) ..."
    return diff


def _load(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def _copilot_chat(token: str, system: str, user: str) -> str:
    payload = json.dumps(
        {
            "model": REVIEW_MODEL,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        }
    ).encode()

    req = urllib.request.Request(
        COPILOT_API,
        data=payload,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Copilot-Integration-Id": "vscode-chat",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            body = json.loads(resp.read())
            return body["choices"][0]["message"]["content"]
    except Exception as exc:
        return f"## Review error\n\nCopilot API call failed: `{exc}`"


def _post_comment(repo: str, pr: str, body: str) -> None:
    token = _required_env("GH_TOKEN")
    cmd = ["gh", "pr", "comment", pr, "--repo", repo, "--body-file", "-"]
    proc = subprocess.run(
        cmd,
        input=body,
        text=True,
        env={**os.environ, "GH_TOKEN": token},
        capture_output=True,
    )
    if proc.returncode != 0:
        print(f"reviewer: gh pr comment failed: {proc.stderr}")
    else:
        print("reviewer: comment posted")


def main() -> int:
    token = _required_env("GH_TOKEN")
    pr = _required_env("PR_NUMBER")
    repo = _required_env("PR_REPO")

    skill = _load(SKILL_PATH)
    agents = _load(AGENTS_PATH)
    diff = _git_diff_against_base()

    if not diff.strip():
        print("reviewer: empty diff, nothing to review")
        return 0

    system = textwrap.dedent(f"""
        You are {REVIEW_MODEL} acting as the second reviewer on a godotty PR.
        Your lens is architectural drift, idiom quality, and subtle bugs.
        Follow the format defined in the dual-review skill below.
        Be terse but specific. Cite filenames and line numbers when possible.
        End with a single line: `### Verdict: LGTM` | `LGTM with nits` | `REQUEST_CHANGES`.

        --- AGENTS.md ---
        {agents}

        --- dual-review skill ---
        {skill}
    """).strip()

    user = f"Review this diff:\n\n```diff\n{diff}\n```"

    review_text = _copilot_chat(token, system, user)

    body = (
        f"## Copilot review — {REVIEW_MODEL}\n\n"
        f"_Lens: architectural drift, idiom quality, subtle bugs._\n\n"
        f"{review_text}\n"
    )
    _post_comment(repo, pr, body)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
