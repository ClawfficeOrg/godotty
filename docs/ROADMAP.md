# Godotty Roadmap — Master Index

> **What this is:** Godotty is a Godot 4.6 reference application and regression
> harness for [godotty-node](https://github.com/ClawfficeOrg/godotty-node), a
> Rust GDExtension that brings real PTY-backed terminal emulation to Godot.
> This roadmap plans the evolution of that demo app into a full-featured,
> WezTerm-inspired terminal widget library for Godot.
>
> **Archive:** completed work lives in the Ralph Loop specs
> (`.ralph/specs/`) and in the git log.

Agents must read `AGENTS.md`, `.ralph/PROMPT.md`, `.ralph/progress/CURRENT.md`,
and the relevant spec before starting any task.

---

## Version Series

| File | Version Series | Theme | Status |
|------|---------------|-------|--------|
| [`docs/todo-v0.md`](todo-v0.md) | 0.x | Developer foundation (infra, CI, test coverage) | 🟡 Active |
| [`docs/todo-v1.md`](todo-v1.md) | 1.x | Terminal emulation quality (VT parity, resize, clipboard) | 🔵 Planned |
| [`docs/todo-v2.md`](todo-v2.md) | 2.x | UX & appearance (themes, fonts, search, keybindings) | 🔵 Planned |
| [`docs/todo-v3.md`](todo-v3.md) | 3.x | Multiplexing (tabs, split panes, session persistence) | 🔵 Roadmap |
| [`docs/todo-v4.md`](todo-v4.md) | 4.x | Advanced features (shell integration, mouse, images) | 🔵 Roadmap |

---

## Phase Summary

| Phase | Title | Status |
|-------|-------|--------|
| 0.2.0 | Developer Infrastructure (Ralph Loop + test harness) | 🟡 In review |
| 0.3.0 | Real-mode Regression CI | 🔵 Planned |
| 0.4.0 | Code Quality Cleanup | 🔵 Planned |
| 1.0.0 | Alternate Screen Buffer | 🔵 Planned |
| 1.1.0 | Cursor Tracking & Styles | 🔵 Planned |
| 1.2.0 | Resize & SIGWINCH | 🔵 Planned |
| 1.3.0 | Bracketed Paste Mode | 🔵 Planned |
| 1.4.0 | Mouse Selection & Clipboard | 🔵 Planned |
| 2.0.0 | Color Scheme System | 🔵 Planned |
| 2.1.0 | Font Configuration | 🔵 Planned |
| 2.2.0 | Search in Scrollback | 🔵 Planned |
| 2.3.0 | Configurable Keybindings | 🔵 Planned |
| 2.4.0 | Visual Tuning (transparency, padding, visual bell) | 🔵 Planned |
| 3.0.0 | Tab Bar | 🔵 Roadmap |
| 3.1.0 | Split Panes | 🔵 Roadmap |
| 3.2.0 | Session Persistence | 🔵 Roadmap |
| 4.0.0 | Hyperlinks (OSC 8) | 🔵 Roadmap |
| 4.1.0 | Shell Integration (OSC 7 + OSC 133) | 🔵 Roadmap |
| 4.2.0 | Mouse Reporting (TUI app support) | 🔵 Roadmap |
| 4.3.0 | Unicode & Wide Characters | 🔵 Roadmap |
| 4.4.0 | Image Protocol (iTerm2 + Sixel) | 🔵 Roadmap |

---

## Design Philosophy

Features are prioritized in the order WezTerm popularized them: solid
emulation quality first, then UX polish, then power-user multiplexing,
then deep shell integration. Every new feature must:

1. Work in **mock mode** — demo app always runs without the GDExtension.
2. Stay behind the `TerminalManager` boundary — views never touch backends directly.
3. Have a test before it ships — RED → GREEN → REFACTOR.
4. Be documented in `README.md` and the relevant `todo-vN.md`.

See `AGENTS.md` §2 for the full quality bar.

---

## WezTerm Inspiration Map

This table maps WezTerm features to Godotty milestones for quick reference.
WezTerm docs: https://wezfurlong.org/wezterm/

| WezTerm feature | Godotty phase |
|----------------|--------------|
| Alternate screen (vim, htop) | 1.0.0 |
| Cursor shape / blink | 1.1.0 |
| Terminal resize + SIGWINCH | 1.2.0 |
| Bracketed paste | 1.3.0 |
| Mouse text selection + copy | 1.4.0 |
| Color schemes (Dracula, Nord, …) | 2.0.0 |
| Font family + size config | 2.1.0 |
| Scrollback search (`/` mode) | 2.2.0 |
| Custom keybindings | 2.3.0 |
| Background transparency | 2.4.0 |
| Multiple tabs | 3.0.0 |
| Split panes | 3.1.0 |
| Hyperlinks (OSC 8) | 4.0.0 |
| OSC 7 (CWD) + OSC 133 (zones) | 4.1.0 |
| Mouse reporting for TUIs | 4.2.0 |
| Wide chars / CJK / Nerd Fonts | 4.3.0 |
| Inline images (iTerm2 / Sixel) | 4.4.0 |
