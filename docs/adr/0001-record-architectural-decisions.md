# 0001 — Record architectural decisions

Date: 2025-01-XX
Status: Accepted

## Context

We need a lightweight way to record the *why* behind architectural choices
so future agents (human or AI) don't have to re-litigate them.

## Decision

Use [ADRs (Architecture Decision Records)](https://adr.github.io/) in
`docs/adr/`, numbered monotonically, immutable once accepted.

Format: short MADR-style entries with Context / Decision / Consequences.
Status values: `Proposed`, `Accepted`, `Deprecated`, `Superseded`.

## Consequences

- New ADRs are added by PR.
- ADRs are referenced from CHANGELOG when behavior changes.
- Specs may cite ADRs but specs are *what to build*, ADRs are *why this shape*.
