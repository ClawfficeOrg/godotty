# Godotty

**Godotty** is a demonstration app for the [godotty-node](https://github.com/ClawfficeOrg/godotty-node) GDExtension, which provides terminal emulation capabilities for Godot 4.6 projects.

![Terminal Demo](screenshots/terminal-demo.png)

## Status

Current release: **v0.1.0** — see [CHANGELOG.md](CHANGELOG.md).

## Features

- 🖥️ **Terminal Emulation** — full ANSI color (256-color, truecolor, OSC sequences)
- 📦 **Mock Mode** — works without the GDExtension for development
- 🎨 **Solarized Dark** palette
- ⌨️ **Command History** — navigate with arrow keys
- 🧠 **Robust ANSI Parser** — handles partial-escape sequences across PTY chunks
- 🔌 **Hot-Swap Backend** — seamlessly switch between mock and real terminal

## Quick Start

### Mock Mode (no GDExtension required)

```bash
cd project
godot4 .
```

Or open `project/project.godot` in the Godot Editor.

### Real Terminal (with godotty-node)

```bash
git clone https://github.com/ClawfficeOrg/godotty-node.git
cd godotty
./build_extension.sh    # builds godotty-node and installs it into project/addons/
cd project
godot4 .
```

## Architecture

Signal-based, with a hard boundary between view and backend.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   TerminalView  │◀──▶│    SignalBus     │◀──▶│ TerminalManager │
│   (UI Layer)    │     │   (Event Bus)    │     │ (mock or real)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**Signals (`SignalBus`):**

| Signal | Purpose |
|---|---|
| `command_submitted(command: String)` | User entered a command. |
| `output_ready(text: String)` | Output ready to display. |
| `terminal_cleared()` | Terminal cleared. |
| `addon_status_changed(available: bool)` | godotty-node detection result. |
| `shell_status_changed(running: bool)` | Shell started/stopped. |

`TerminalView` and `TerminalManager` only talk via `SignalBus`. Direct
calls across that boundary are forbidden — see
[`AGENTS.md`](AGENTS.md) §2.5.

## Mock command set

| Command | Description |
|---------|-------------|
| `help` | Show available commands |
| `clear` | Clear the terminal |
| `echo <text>` | Echo text back |
| `pwd` | Print working directory |
| `cd <dir>` | Change directory |
| `ls` | List files |
| `cat <file>` | Show file contents |
| `date` | Show current date/time |
| `whoami` | Show current user |
| `exit` | Exit the shell |

Full mock spec: [`project/docs/mock-terminal-commands.md`](project/docs/mock-terminal-commands.md).

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| `Enter` | Submit command |
| `↑` / `↓` | Navigate command history |
| `Ctrl+C` | Send SIGINT (real PTY) / clear input (mock) |
| `Ctrl+L` | Clear terminal |
| `Ctrl+D` | Send EOF |

## Project layout

```
.github/        — workflows, skills, agents, issue templates
.ralph/         — Ralph Loop state (specs, progress, learnings)
project/        — the Godot project
  autoload/     — SignalBus, TerminalManager
  scenes/       — main.tscn, terminal.tscn
  scripts/      — terminal_view.gd
  resources/    — themes
  docs/         — in-project docs
tests/          — GdUnit4 test suites (unit + integration)
docs/           — top-level docs (ADRs)
scripts/        — ralph_loop, run_tests, lint, release, install_gdunit4
```

## Development

This repo is developed in the open by an autonomous agent loop —
**Ralph Loop** + **Superpowers** — supervised by a human maintainer.
See:

- [`AGENTS.md`](AGENTS.md) — the agent constitution.
- [`.ralph/README.md`](.ralph/README.md) — the loop's operational manual.
- [`.github/skills/INDEX.md`](.github/skills/INDEX.md) — on-demand skill packs.
- [`docs/adr/`](docs/adr/) — architectural decision records.

### Requirements

- Godot 4.6+
- Rust 1.70+ (only for building godotty-node)
- For tests: `python3`, `gdtoolkit` (`pip install gdtoolkit`), GdUnit4
  (installed via `scripts/install_gdunit4.sh`).

### Running tests

```bash
scripts/run_tests.sh                    # all tests, headless
scripts/run_tests.sh tests/unit         # subset
```

### Linting

```bash
scripts/lint.sh         # gdformat --check, gdlint, shellcheck
```

### Cutting a release

Maintainer-only (Hard Stop in `AGENTS.md` §9):

```bash
scripts/release.sh v0.2.0
```

### Running the autonomous loop

```bash
RALPH_AGENT_CMD=claude scripts/ralph_loop.sh --max-iter 10
touch .ralph/state/STOP        # graceful halt
```

See [`.github/skills/ralph/ralph-loop-iteration/SKILL.md`](.github/skills/ralph/ralph-loop-iteration/SKILL.md)
for what the agent does each iteration.

## Code review

Every PR receives:

1. **Claude review** — process compliance + concrete behavior
   ([skill](.github/skills/review/dual-review/SKILL.md)).
2. **GPT-5 review** — architectural drift, idiom, edge cases.
3. **Human sign-off** for anything touching autoloads, the GDExtension
   boundary, CI/release infra, or `TerminalManager`'s public API.

The dual-review workflow runs on every PR (`.github/workflows/dual-review.yml`).
If `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` is unset, that reviewer is
skipped with a warning.

## Related

- [godotty-node](https://github.com/ClawfficeOrg/godotty-node) — the GDExtension this app demos.
- [Clawffice-Space](https://github.com/ClawfficeOrg/Clawffice-Space) — the main Clawffice project.

## License

MIT — see [LICENSE](LICENSE).

---

*Part of the Clawffice Collective* 🦞🤖
