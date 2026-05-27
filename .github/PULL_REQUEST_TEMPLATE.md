# Pull Request

**Spec:** `.ralph/specs/NNNN-<slug>.md`
**Closes:** #<issue>

## Summary

(What changed and why. 1–3 paragraphs. The diff says how; this section
says what & why.)

## Acceptance

(Mirror the spec's acceptance list here, with current state.)

- [ ] …
- [ ] CHANGELOG entry added under `[Unreleased]`.
- [ ] README updated (if user-visible).
- [ ] Tests added: `tests/<unit|integration>/<file>_test.gd`.
- [ ] `.ralph/learnings/INDEX.md` updated (if a quirk was hit).

## Test evidence

```
$ scripts/run_tests.sh
... paste actual output here, no paraphrasing ...
```

## Risks

- (What could go wrong? What did you not test?)

## Reviewers

- @claude (process compliance)
- @gpt5 (architectural / idiom — via dual-review.yml)
- @hippo (final sign-off if any Hard Stop touched)

---

*Conventional Commits format on every commit. See
`.github/skills/git/conventional-commits/SKILL.md`.*
