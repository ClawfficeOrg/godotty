# 0002 — Adopt Ralph Loop + Superpowers for autonomous development

Date: 2025-01-XX
Status: Accepted

## Context

After memory corruption in OpenClaw fragmented several Clawffice projects,
we wanted a way for godotty (and its sibling repos) to keep moving
forward with minimal human intervention. The two patterns we evaluated:

- **Ralph Loop** (Geoffrey Huntley): a stateless loop where an LLM agent
  re-reads disk-resident state every iteration. Eliminates conversation-
  history drift; forces the agent to leave breadcrumbs.
- **Superpowers** (Jesse Vincent / Obra): on-demand markdown "skill packs"
  with `name`/`description`/`when_to_use` frontmatter. The agent loads
  only relevant skills, keeping context windows small.

Neither is a complete system on its own. Ralph Loop has no opinion on
*how* the agent should make decisions inside an iteration; Superpowers
has no opinion on *when* to keep iterating.

## Decision

Combine both:

1. **Ralph Loop** governs *iteration shape*: read state → pick smallest
   unit → RED → GREEN → REFACTOR → commit → push → exit. The driver
   (`scripts/ralph_loop.sh`) re-invokes the agent. State on disk
   (`.ralph/`) is the only memory.

2. **Superpowers** governs *skill use*: the agent reads
   `.github/skills/INDEX.md`, loads only the skills relevant to the unit,
   and proceeds.

3. **AGENTS.md** is the constitution that binds them: principles
   (Brutal Honesty, Verification Before Completion, etc.), Hard Stops,
   commit format, review protocol.

4. **Dual review** (Claude + GPT-5): two reviewers with deliberately
   different lenses. Disagreement bumps to a human.

## Consequences

- Onboarding a new agent is just "read AGENTS.md, then PROMPT.md".
- Reverts and audits are straightforward: every iteration is a real
  commit; CURRENT.md was its working memory; learnings/INDEX.md is
  curated wisdom.
- We accept the cost of writing skill packs upfront (~10 skill files at
  bootstrap). The payoff is consistent agent behavior across runs.
- We accept the cost of two reviewers per PR. The payoff is catching
  the things one model misses.
- The driver does **not** run tests itself — the agent does. This forces
  honest reporting; an agent that fakes "tests pass" leaves no green
  CHANGELOG entry, no green CI run.

## Alternatives considered

- **Pure conversation-history mode**: rejected — context window cliff,
  no reproducibility, no audit trail.
- **Single-reviewer mode**: rejected — too easy to confirm-bias.
- **Codex-only / Cursor-only**: rejected on lock-in; the driver
  abstracts the agent CLI behind `RALPH_AGENT_CMD`.

## References

- Geoffrey Huntley — *Ralph Wiggum as a Software Engineer*
- Jesse Vincent — Superpowers / claude-skills
- ADR-0001 (this repo) — ADR system bootstrap
- `AGENTS.md`, `.ralph/README.md`
