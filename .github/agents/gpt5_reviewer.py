#!/usr/bin/env python3
"""GPT-5 PR reviewer — posts a structured review as a PR comment.

Loaded by .github/workflows/dual-review.yml. Uses the dual-review skill
file as the system prompt to keep behavior in lockstep with the Claude
reviewer's checklist.

Env:
    OPENAI_API_KEY  required
    GH_TOKEN        required (workflow's GITHUB_TOKEN is fine)
    PR_NUMBER       required
    PR_REPO         required (e.g. "ClawfficeOrg/godotty")
    OPENAI_MODEL    optional, default "gpt-5"

Failures here are non-fatal to CI (continue-on-error in the workflow);
the script logs and returns 0 unless argv parsing fails.
"""
from __future__ import annotations

import json
import os
import pathlib
import subprocess
import sys
import textwrap

try:
    from openai import OpenAI  # type: ignore
except ImportError:  # pragma: no cover
    print("gpt5_reviewer: openai package missing; aborting softly")
    sys.exit(0)


REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
SKILL_PATH = REPO_ROOT / ".github" / "skills" / "review" / "dual-review" / "SKILL.md"
AGENTS_PATH = REPO_ROOT / "AGENTS.md"


def _required_env(name: str) -> str:
    val = os.environ.get(name)
    if not val:
        print(f"gpt5_reviewer: missing required env var {name}; skipping")
        sys.exit(0)
    return val


def _git_diff_against_base() -> str:
    """Return the unified diff of the PR head against its merge base with master."""
    try:
        base = subprocess.check_output(
            ["git", "merge-base", "origin/master", "HEAD"], cwd=REPO_ROOT, text=True
        ).strip()
        diff = subprocess.check_output(
            ["git", "diff", base, "HEAD"], cwd=REPO_ROOT, text=True
        )
    except subprocess.CalledProcessError as exc:
        print(f"gpt5_reviewer: git diff failed: {exc}")
        return ""
    # GPT-5 has plenty of context but be polite.
    if len(diff) > 200_000:
        diff = diff[:200_000] + "\n\n... (diff truncated for review) ..."
    return diff


def _load(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def _post_comment(repo: str, pr: str, body: str) -> None:
    token = _required_env("GH_TOKEN")
    cmd = [
        "gh", "pr", "comment", pr,
        "--repo", repo,
        "--body-file", "-",
    ]
    env = {**os.environ, "GH_TOKEN": token}
    proc = subprocess.run(cmd, input=body, text=True, env=env, capture_output=True)
    if proc.returncode != 0:
        print(f"gpt5_reviewer: gh pr comment failed: {proc.stderr}")
    else:
        print("gpt5_reviewer: comment posted")


def main() -> int:
    api_key = _required_env("OPENAI_API_KEY")
    pr = _required_env("PR_NUMBER")
    repo = _required_env("PR_REPO")
    model = os.environ.get("OPENAI_MODEL", "gpt-5")

    skill = _load(SKILL_PATH)
    agents = _load(AGENTS_PATH)
    diff = _git_diff_against_base()

    if not diff.strip():
        print("gpt5_reviewer: empty diff, nothing to review")
        return 0

    system = textwrap.dedent(f"""
        You are GPT-5 acting as the *second* reviewer on a godotty PR.
        Your lens is **architectural drift, idiom quality, and subtle bugs**
        — not process compliance (Claude handles that).

        You MUST follow the format defined in the dual-review skill, below.
        Be terse but specific. Cite filenames and line numbers when possible.
        End with a single line: `### Verdict: LGTM` | `LGTM with nits` | `REQUEST_CHANGES`.

        --- AGENTS.md (the project constitution) ---
        {agents}

        --- dual-review skill ---
        {skill}
    """).strip()

    user = textwrap.dedent(f"""
        Below is the unified diff of the PR. Review it.

        ```diff
        {diff}
        ```
    """).strip()

    client = OpenAI(api_key=api_key)
    try:
        resp = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        )
        review_text = resp.choices[0].message.content or ""
    except Exception as exc:  # broad on purpose: this is non-fatal
        review_text = f"## GPT-5 review — error\n\nFailed to obtain review: `{exc}`"
        print(f"gpt5_reviewer: API call failed: {exc}")

    body = (
        f"## GPT-5 review — {model}\n\n"
        f"_Lens: architectural drift, idiom quality, subtle bugs._\n\n"
        f"{review_text}\n"
    )
    _post_comment(repo, pr, body)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
