# Godotty Todo — v3.x: Multiplexing

> Back to index: [`docs/ROADMAP.md`](ROADMAP.md)

The 3.x series adds WezTerm-style multiplexing: a tab bar for running
multiple independent shells in the same window, split panes for side-by-side
workflows, and optional session persistence so sessions survive restarts.

**Prerequisite:** all of Phase 2.x stable. Multiplexing requires the
`TerminalManager` / `TerminalView` pair to be instanced multiple times
simultaneously — any global state in the autoloads must be removed or
scoped first (that cleanup is gated on the Phase 2.3 keybinding refactor
which already moves state into resources).

**Architecture note:** each tab and each pane gets its own
`TerminalManager` instance (not the autoload singleton) and its own
`TerminalView` node. The `SignalBus` autoload remains global but messages
are tagged with a `terminal_id: int`. Detailed breakdown deferred until
Phase 2.x is stable; task cards below describe intended scope.

---

## Phase 3.0.0 — Tab Bar

**Goal:** a tab bar at the top of the window shows open terminals; users
can open, close, and cycle tabs. Each tab is an independent shell session.

**Prerequisite:** all of Phase 2.x. TerminalManager must be instancable
(not singleton-only). Tracked in ADR — consult maintainer before starting
(AGENTS.md hard-stop: new autoload or public API change).

**Note:** detailed task breakdown deferred until Phase 2.x nears completion.

Planned scope:

- [x] `3.0.1` Multi-instance `TerminalManager` (remove singleton dependency).
  - Refactor `TerminalManager` from a pure autoload singleton into a node
    that can be instanced per-tab. Autoload becomes a "default" instance
    registry. **Hard-stop: requires human sign-off** (public API change).

- [x] `3.0.2` `TabBar` node with add / close buttons.
  - A `HBoxContainer`-based tab bar. Each tab shows shell name (from OSC 0/2
    or process argv), a close button, and an indicator dot when output
    has arrived since last focus.

- [x] `3.0.3` Ctrl+T / Ctrl+W / Ctrl+Tab keybindings for tab management.
  - Integrated with `TerminalKeymap` (Phase 2.3.0).

- [ ] `3.0.4` Tab title updates from OSC 0/2 (window title sequences).
  - Shell sets tab title via `echo -e '\033]0;My Tab\007'`.

- [ ] `3.0.5` RC cut and multi-model review.

**Release gate for 3.0.0:** open 3 tabs, run different commands in each,
close the middle tab; tabs are fully independent; Ctrl+Tab cycles.

---

## Phase 3.1.0 — Split Panes

**Goal:** split the terminal window horizontally or vertically into
independent panes. Each pane runs its own shell.

**Prerequisite:** Phase 3.0.0 (multi-instance TerminalManager).

**Note:** detailed task breakdown deferred until Phase 3.0.0 ships.

Planned scope:

- [ ] `3.1.1` `SplitTerminalContainer` node wrapping a `SplitContainer`.
  - Wraps Godot's built-in `SplitContainer`. Each split child is either a
    `TerminalView` or another `SplitTerminalContainer` (recursive).

- [ ] `3.1.2` Ctrl+Shift+E (split right) / Ctrl+Shift+O (split down).
  - Integrated with `TerminalKeymap`. Spawns a new `TerminalView` + manager
    in the appropriate split direction.

- [ ] `3.1.3` Pane focus navigation with Ctrl+Arrow.
  - Cycles focus between visible panes in reading order.

- [ ] `3.1.4` Close pane (Ctrl+Shift+W).
  - Removes the pane from the split; sibling expands to fill space.
    Prompts if the shell is running a foreground process.

- [ ] `3.1.5` Resize handle drag.
  - Expose the `SplitContainer`'s drag handle; store ratio in
    `TerminalSettings`.

**Release gate for 3.1.0:** split window into 2 vertical panes; run
`htop` in one and a shell in the other; both operate independently;
resize handle works.

---

## Phase 3.2.0 — Session Persistence

**Goal:** terminal sessions (scrollback, CWD, command history) survive
Godot process restarts. On startup, offer to restore the previous session.

**Prerequisite:** Phase 3.1.0 (tabs + panes define the session topology).

**Note:** detailed task breakdown deferred until multiplexing is stable.
This phase is very long-term and may be restructured based on user feedback
after 3.0–3.1 ship.

Planned scope:

- [ ] `3.2.1` Session serialization format.
  - A JSON or `.tres` file at `user://sessions/latest.json` encoding the
    tab / pane topology, CWD per pane (from OSC 7, Phase 4.1.0), command
    history, and optionally a scrollback snapshot.

- [ ] `3.2.2` Restore on startup.
  - On launch, if a session file exists and is < 24 hours old, prompt the
    user to restore. Re-spawns shells in saved CWDs.

- [ ] `3.2.3` Reconnect to existing tmux / screen session (opt-in).
  - If the saved session referenced a `tmux` session that is still alive,
    offer to `tmux attach` instead of spawning a fresh shell.

**Release gate for 3.2.0:** close and reopen the app; previous tabs and
CWDs are restored; history is preserved.
