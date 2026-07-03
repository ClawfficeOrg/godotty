# Fable Review — Godotty Codebase

**Date:** 2026-07-03
**Reviewer:** Claude (Fable 5)
**Scope:** full repo at `master` (5868905), focus on `project/` GDScript sources,
build/install scripts, and the mock/real backend boundary.
**Companion:** Part 2 of this document is the plan for real Windows shell
support (PowerShell, Git Bash, cmd).

---

## 1. Summary

Godotty is in good shape for a demo/regression harness: the SignalBus boundary
is respected, test discipline is real (500+ GdUnit4 tests), docs and process
files are unusually thorough, and the ANSI parser has clearly been hardened
against real-world traffic (Starship, ZLE redraws, cross-chunk escapes).

The two structural risks are:

1. **`terminal_view.gd` is a 1,864-line monolith** that mixes ANSI parsing,
   BBCode generation, rendering, input handling, selection, search, and
   settings UI. The gdlint `max-file-lines` cap has been raised six times
   (700 → 1850) to accommodate it. The parser needs to be extracted.
2. **The string-rebuild rendering model is O(N²)** under common shell behavior
   (prompt redraws, scrollback overflow), which will not survive real daily
   use with a 1,000+ line scrollback.

Plus one architectural bug that blocks the tabs feature (§3.1).

Severity legend: 🔴 fix before next feature work · 🟠 fix soon · 🟡 cleanup / low risk.

---

## 2. What's good

- **Boundary discipline.** Views talk to backends only via `SignalBus` /
  `TerminalManager`; the mock backend is genuinely first-class, so the demo
  runs everywhere. This is rare and worth protecting.
- **Two-pass SGR diffing** (`terminal_view.gd:872`) is the correct design for
  BBCode's strict nesting; the close-all/reopen approach eliminates the whole
  class of orphaned-tag bugs that the git history shows were fought one at a
  time before it.
- **Cross-chunk correctness.** Partial-escape buffering (`_partial_escape`),
  the `_pending_line_clear` cross-chunk CR fix, and `[lb]`/`[rb]` bracket
  escaping all show the parser was debugged against real PTY chunk boundaries,
  not synthetic input.
- **Test-first culture is visible in the artifact trail** — nearly every
  feature in `.ralph/progress/CURRENT.md` lands with a named test file, and
  regression tests were written for each rendering bug.
- **`TerminalGrid`** (`project/scripts/terminal_grid.gd`) is clean, cohesive,
  well-documented, and does line reflow on resize correctly. Model for what
  extracted modules should look like.

---

## 3. Findings

### 3.1 🔴 Multi-tab output crosstalk through SignalBus

`TerminalManagerNode` exists so each tab can own a manager, but both its mock
and real paths emit on the **global** bus
(`terminal_manager_node.gd:197`, `:388`):

```gdscript
output_received.emit(line)
SignalBus.output_ready.emit(line)
```

Meanwhile `TerminalView._ready()` (`terminal_view.gd:230`) subscribes to
`SignalBus.output_ready` unconditionally — it never connects to the injected
`manager`'s `output_received` signal (only `theme_changed` is per-manager).
With two tabs open, every view renders every shell's output, duplicated.
Same for `terminal_cleared` / `shell_status_changed`.

**Fix:** when `manager != null`, connect to `manager.output_received` /
`shell_started` / `shell_stopped` directly and *skip* the SignalBus
subscriptions; `TerminalManagerNode` should not emit on SignalBus at all
(that's the autoload's job as the app-wide default). This is a
`TerminalManager` boundary change → human sign-off per AGENTS.md §9.

### 3.2 🔴 O(N²) full-buffer re-render on hot paths

Two code paths clear the `RichTextLabel` and re-parse the **entire**
`_raw_accumulator` through `_ansi_to_bbcode`:

- `_append_output` line-clear path (`terminal_view.gd:1056-1082`) — triggered
  by every standalone CR, i.e. **every prompt redraw** in ZSH/Starship setups.
- `_enforce_scrollback_limit` (`terminal_view.gd:1106`) — triggered on **every
  appended line** once scrollback is full (steady state for any long session).

With `scrollback_lines = 1000`, a `yes`-style output stream or a busy build log
re-parses ~1000 lines of ANSI per PTY chunk. This is the biggest obstacle to
using Godotty as a real terminal.

**Fix direction:** keep scrollback as an `Array[String]` of *lines* (raw and
rendered in parallel), so a CR line-rewrite touches only the last line and
scrollback trim is a cheap `pop_front()` + `RichTextLabel.remove_paragraph(0)`.
This also removes the giant-string `.substr`/`.rfind` churn.

### 3.3 🔴 `terminal_view.gd` monolith — extract the parser

1,864 lines, six responsibilities, six gdlint limit bumps. Concretely:

- `_ansi_to_bbcode`, `_handle_sgr`, `_close_all_tags`, `_open_active_tags`,
  `_xterm256_hex`, `_indexed_color`, `_strip_ansi`, `_partial_escape` state →
  new `AnsiParser` (RefCounted, `class_name`), unit-testable without a scene.
- Search (`search_scrollback`, `get_highlighted_line`,
  `_render_highlighted_scrollback`, match state) → `ScrollbackSearch` helper.
- Selection + context menu could follow later.

The parser extraction is near-mechanical (state vars move with the methods)
and instantly halves the file. It also unblocks reusing the parser from
`TerminalManagerNode` or future split panes without a `Control` instance.

### 3.4 🟠 ~390 lines duplicated between autoload and node manager

`project/autoload/terminal_manager.gd` and
`project/scripts/terminal_manager_node.gd` are near-identical copies (mock
command set, real spawn logic, signal plumbing). The bug in §3.1 exists partly
*because* of this duplication; the two files have already drifted
(`_registered_default` and the `terminal_resized` subscription exist only in
the autoload).

**Fix:** make the autoload a thin wrapper that instantiates/owns a
`TerminalManagerNode` (or have both extend a shared base). New autoload =
Hard Stop, but restructuring the existing one behind its current API is not.

### 3.5 🟠 Selection, cursor overlay, and mouse math ignore scroll offset

- `_pixel_to_cell` (`terminal_view.gd:503`) maps control-local pixels to cells
  without adding `scroll_container.scroll_vertical`, and
  `get_selected_text` (`:583`) indexes `get_parsed_text()` lines by that same
  screen row. Once output exceeds one screen, click-drag selects and copies
  the *wrong lines* (off by scroll amount).
- `_update_cursor_overlay` (`:1458`) mixes coordinate spaces: `cursor_row`
  comes from CSI H (viewport-relative) but the overlay is positioned in
  content coordinates inside the ScrollContainer.

**Fix:** convert through
`row = int((pos.y + scroll_container.scroll_vertical) / line_height)` for
selection, and anchor the cursor overlay to the *last* rendered line in
primary mode rather than trusting CSI H rows (streaming primary mode has no
fixed viewport anyway — same reasoning already applied to `ESC[J` mode 0).

### 3.6 🟠 xterm-256 color cube uses wrong ramp

`_xterm256_hex` (`terminal_view.gd:1025`) computes cube channels as `n * 51`
(0, 51, 102, …, 255). The xterm spec ramp is `0, 95, 135, 175, 215, 255`
(i.e. `55 + 40n` for n > 0). Every 256-color theme (vim airline, htop bars,
`ls` dircolors) renders visibly darker/shifted at the low end.

Also: the channel order decodes as `b = i % 6`, `r = (i / 36) % 6` — that part
is correct (index = 16 + 36r + 6g + b), just fix the ramp values.

### 3.7 🟠 SGR coverage gaps

`_handle_sgr` (`terminal_view.gd:872`) handles bold/underline/colors but
silently drops: `3`/`23` (italic — RichTextLabel supports `[i]`), `7`/`27`
(reverse video — swap fg/bg), `2` (dim), `9`/`29` (strikethrough — `[s]`).
Reverse video especially: many TUI status bars and `less` highlights use it,
and dropping it loses the highlight entirely. `TerminalGrid` cells already
carry an `italic` field that nothing sets.

### 3.8 🟠 `_real_clear` injects a command string into the PTY

`terminal_manager.gd:364` writes `"clear\n"` to the shell's stdin. If a TUI
app is running (vim, htop) this types the word "clear" into it. It also
breaks on cmd.exe (`cls`) — relevant to the Windows plan.

**Fix:** clear is a *view* operation in a streaming terminal: wipe the display
and accumulators host-side (as mock does) and don't write to the PTY at all.
If shell cooperation is wanted, send the VT sequence `[2J[H` to
the *parser*, not the shell's input.

### 3.9 🟠 Search-highlight path re-introduces the bracket-escaping bug

`get_highlighted_line` (`terminal_view.gd:1782`) and
`_render_highlighted_scrollback` (`:1861`) escape with `xml_escape()` only.
The main render path learned (commit 376b4f8) that `[` / `]` must become
`[lb]` / `[rb]` or RichTextLabel mis-parses. Search any scrollback containing
`[` (Starship segments, log timestamps) → malformed BBCode again, and the
injected `[bgcolor=…]` highlight tags can be broken by adjacent literal
brackets.

**Fix:** shared `escape_for_bbcode(text)` helper used by both paths (natural
home: the extracted `AnsiParser`).

### 3.10 🟡 Resize plumbing inconsistencies

`_on_viewport_resize` (`terminal_view.gd:1409`):

- Emits `SignalBus.terminal_resized(cols, rows)` with **unclamped** values,
  then clamps before calling `manager.resize()` — two consumers see different
  dimensions.
- `char_w = font_size * 0.5` is a hardcoded aspect guess. Measure the actual
  font: `font.get_string_size("M", ..., font_size).x` — Departure Mono and
  JetBrains Mono have different advances, so cols drift from reality.
- Listens only to window `size_changed`; per-control size changes (tab/split
  layouts) won't retrigger. Use `Control.resized` on the view itself.

### 3.11 🟡 Committed binary vs. stated policy

`project/addons/godotty-node/bin/windows/godotty_node.dll` is committed, while
AGENTS.md §8 and the README describe `project/addons/` as gitignored. A stale
DLL built against a mismatched godot-rust API is the suspected source of the
`0xc0000142` crash that forced Windows into mock mode. Either remove it and
document a download/build step, or version it deliberately (with the
godotty-node ref it was built from recorded next to it).

### 3.12 🟡 Small items

| Where | Issue |
|---|---|
| `terminal_manager.gd:235` | `cd ..` from `/home` is a no-op (`parts.size() > 2` guard); can never reach `/`. |
| `terminal_manager.gd:115` | `has_output()` inlines the buffer check instead of calling `_mock_has_output()` (which is then dead code). |
| `terminal_view.gd:1017` | `_indexed_color(idx, _bright)` — `_bright` param unused; drop it. |
| `terminal_view.gd:1825` | `_strip_ansi` compiles its RegEx on every call; it's called per-line in loops. Cache as a static/const. |
| `terminal_view.gd:1483` | Blink `Timer.wait_time` read once; runtime changes to `TerminalSettings.cursor_blink_rate` never apply. |
| `project/resources/terminal_settings.gd` | Unused-looking Resource duplicate of the static `TerminalSettings` class; two sources of truth for font_size/blink defaults (14 vs 20, etc.). Consolidate or delete. |
| `main.gd:19` | `await get_tree().process_frame` to dodge autoload ordering — fragile; autoloads are ready before scene `_ready` in Godot 4, so this likely masks something else or is unnecessary. |
| `README.md` | Says "Solarized Dark palette" as *the* palette and font README/scene reference Departure Mono while `TerminalSettings` bundles JetBrains Mono — drift; update per AGENTS.md §2.6. |
| Test suite | `.ralph/progress/CURRENT.md` reports 7 pre-existing failures out of 505. Per AGENTS.md §2.1 these should be triaged (fix or document with evidence), not carried. |
| `terminal_view.gd:40` | `DEBUG_PTY_CHUNKS` debug scaffolding committed (correctly `false`, but consider stripping now that the CR bug is fixed — commit 5868905 was triage aid). |

---

# Part 2 — Plan: Windows shell support (PowerShell, Git Bash, cmd)

## Current state

Windows is **hard-forced into mock mode** in two places:

- `project/autoload/terminal_manager.gd:77`
- `project/scripts/terminal_manager_node.gd:68`

```gdscript
# Force mock mode on Windows - portable_pty has DLL initialization issues (0xc0000142)
if OS.has_feature("windows"):
```

Everything downstream (parser, view, input) is shell-agnostic VT handling and
already sends ConPTY-compatible input (`\r` for Enter, `` for Ctrl+C),
so the work splits into: (A) unblock the native PTY on Windows (upstream),
(B) shell-profile selection in this repo, (C) per-shell quirks, (D) CI.

## Phase W0 — Unblock the GDExtension (upstream godotty-node; issues, not code, in this repo)

Per AGENTS.md §1, godotty-node changes are out of scope here — file issues and
pin the fixed ref. Needed upstream:

1. **Fix `0xc0000142` DLL init failure.** Likely causes, in order:
   stale committed DLL built against godot-rust API 4.3 while the runtime is
   4.6 (same ABI mismatch already seen as SIGTRAP on Linux — see
   `GODOTTY_FORCE_MOCK` comment `terminal_manager.gd:65`); or a missing
   transitive DLL. Action: rebuild against Godot 4.6 headers
   (`api-custom` / matching `compatibility_minimum`), verify with
   `dumpbin /dependents godotty_node.dll` that only system DLLs are imported
   (portable-pty's ConPTY backend needs no winpty.dll).
2. **ConPTY backend confirmation.** `portable_pty::native_pty_system()`
   already selects ConPTY on Windows ≥ 1809; ensure the crate feature isn't
   pinned to winpty and that resize goes through `ConPTY::resize`.
3. **API: parameterized spawn.** `TerminalNode2D.spawn_shell()` currently
   spawns a fixed default. Request:
   `spawn_shell_with(command: String, args: PackedStringArray, cwd: String, env: Dictionary)`
   (keep zero-arg `spawn_shell()` for compat). This is the one upstream API
   this plan depends on.
4. **CI artifact:** windows-latest job producing `godotty_node.dll`, published
   per-release so this repo can pin `GODOTTY_NODE_REF` (mechanism already
   exists: `scripts/bump_godotty_node_ref.sh`).

## Phase W1 — Remove the force-mock, behind a flag (this repo, reversible)

Per AGENTS.md §2.7 (additive, feature-gated):

- Replace the unconditional Windows block with:
  ```gdscript
  if OS.has_feature("windows") and OS.get_environment("GODOTTY_WINDOWS_REAL") != "1":
      # mock until the ConPTY build is verified; opt in with GODOTTY_WINDOWS_REAL=1
  ```
- `GODOTTY_FORCE_MOCK=1` keeps working as the universal escape hatch.
- Once W0 ships and real mode survives the integration suite on Windows,
  delete the guard entirely (flag flip = one-line commit, easy revert).
- Do the same in **both** manager files — or better, land the §3.4
  de-duplication first so it's one place.

## Phase W2 — Shell profiles (the user-visible feature)

New resource `project/resources/shell_profile.gd`:

```gdscript
class_name ShellProfile
extends Resource
@export var display_name: String = ""     # "PowerShell", "Git Bash", "cmd"
@export var executable: String = ""       # absolute path or bare name
@export var args: PackedStringArray = []
@export var env: Dictionary = {}
@export var cwd: String = ""              # "" = inherit
```

New helper `project/scripts/shell_detector.gd` (static, unit-testable with an
injectable `file_exists` func):

| Profile | Detection order | Spawn |
|---|---|---|
| **PowerShell** | `pwsh.exe` on PATH (PS 7) → `powershell.exe` (Windows PS 5.1, always present) | `pwsh.exe -NoLogo` |
| **cmd** | `%COMSPEC%` → `C:\Windows\System32\cmd.exe` | `cmd.exe` |
| **Git Bash** | `where git` → `<gitroot>\bin\bash.exe`; fallbacks `C:\Program Files\Git\bin\bash.exe`, `%LOCALAPPDATA%\Programs\Git\bin\bash.exe` | `bash.exe --login -i` |
| **WSL** (stretch) | `wsl.exe` present *and* `wsl -l -q` non-empty | `wsl.exe` |
| non-Windows default | `$SHELL` → `/bin/bash` | unchanged behavior |

PATH probing via `OS.execute("where", [name])` on Windows /
`OS.execute("which", [name])` elsewhere; wrap in one
`ShellDetector.find_executable(name)` so tests can stub it.

Wiring:

- `TerminalManager.spawn_shell(profile: ShellProfile = null)` — default null
  preserves today's behavior. **Public API signature change → Hard Stop,
  human sign-off required (AGENTS.md §9)** before implementation.
- Real path forwards to upstream `spawn_shell_with(...)` from W0.3; mock path
  uses `profile.display_name` to pick a mock flavor (see W3).
- UI: `OptionButton` shell picker in the TitleBar (next to ThemeMenu),
  populated from `ShellDetector.available_profiles()`; per-tab default
  profile stored in `TerminalSettings.default_profile_name` (static var,
  same pattern as `selected_theme_name`). New-tab flow (`tab_new_requested`)
  passes the picker's current profile.

## Phase W3 — Per-shell quirks

1. **Clear:** implement §3.8 first (host-side clear); then no per-shell
   `clear`/`cls`/`Clear-Host` special-casing is needed at all.
2. **Encoding:** ConPTY I/O should be UTF-8. cmd sessions default to the OEM
   codepage — spawn cmd profiles with `args = ["/K", "chcp 65001>nul"]`, and
   ask upstream (W0) to set `CreatePseudoConsole` input/output CP explicitly.
   PowerShell profile env: `{"POWERSHELL_TELEMETRY_OPTOUT": "1"}` and
   `[Console]::OutputEncoding` is UTF-8 by default under ConPTY on PS7.
3. **Line endings:** ConPTY delivers `\r\n`; parser already handles the pair
   (`terminal_view.gd:818`). Git Bash delivers `\n`-heavy output with bare-CR
   progress bars (git clone, curl) — the `_pending_line_clear` machinery
   covers it, but the §3.2 perf fix should land *before* Windows enablement,
   because Git Bash progress bars emit standalone CRs at high frequency
   (worst case for the current full-rebuild path).
4. **Keys:** current `_key_to_pty_seq` VT sequences are what ConPTY expects
   (it translates VT input to console events). Two gaps worth adding while in
   there: Alt+key → `ESC` prefix, and Ctrl+arrows → `ESC[1;5C/D` (word-jump
   in PowerShell/cmd line editing).
5. **`cd` tracking / prompt:** none needed — real shell owns it.

## Phase W4 — Tests + CI

- **Unit (mock, all platforms):** `shell_detector_test.gd` — profile
  resolution with stubbed `file_exists`/`find_executable`; profile-arg
  construction per shell; settings persistence of selected profile.
- **Integration (real, Windows, gated on addon presence like
  `tests/integration/real/`):** spawn each detected shell; assert prompt
  output arrives; `echo hello` round-trip (`echo` works verbatim in all
  three shells); exit-code propagation (`exit 3` / `$LASTEXITCODE` / `%ERRORLEVEL%`).
- **CI:** add `windows-latest` to the test workflow — mock-mode suite
  immediately (works today), real-mode job once W0.4 artifacts exist
  (pattern: nightly-real workflow from spec 0003).
- **`build_extension.sh`:** add a Windows branch —
  `MINGW*|MSYS*|CYGWIN*)` → copy `target/release/godotty_node.dll` to
  `bin/windows/` (script already runs under Git Bash).

## Order of operations & risk

```
§3.8 host-side clear ─┐
§3.2 perf fix ────────┼─→ W1 flag-gated enable → W2 profiles → W3 quirks → W4 CI
W0 upstream issues ───┘         (Hard Stop review here ↑)
```

- W0 is the long pole and out of this repo's hands — file the issues first.
- W1 is a two-line diff, fully reversible, and lets anyone with a working
  local DLL test immediately.
- W2's API change is the only Hard Stop; everything else is additive.
- Biggest technical risk: §3.2 (CR-storm perf) making real Windows shells
  *feel* broken even when the PTY works — hence sequenced before enablement.
