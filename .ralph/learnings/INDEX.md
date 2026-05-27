# Project Learnings — INDEX

Append-only log of non-obvious things the agent has learned.
**Newest at top.** Each entry: date, one-line summary, evidence/links.

Format:

    ## YYYY-MM-DD — short title
    **Context:** what we were doing
    **Learning:** the thing
    **Evidence:** commit / PR / line ref
    **Tag:** godot | gdscript | pty | ci | git | windows | macos | linux

---

## 2026-03-23 — GdUnit4 repo moved orgs; v5.x is Godot 4.3/4.4 only

**Context:** First Ralph iteration, installing GdUnit4 from the URL in
`scripts/install_gdunit4.sh` (pinned to `MikeSchulze/gdUnit4 v5.0.5`).
**Learning:** v5.0.5 fails to compile on Godot 4.6 (`get_as_text()` arity
change, `CallableDoubler.call(StringName, ...)` mismatch). The project also
moved to **`godot-gdunit-labs/gdUnit4`**. Use **v6.1.3** (or newer in the
v6.1.x line) for Godot 4.6.
**Evidence:** `scripts/install_gdunit4.sh`, spec 0002.
**Tag:** godot · gdunit · ci

## 2026-03-23 — GdUnit4 CmdTool refuses headless without `--ignoreHeadlessMode`

**Context:** Running `scripts/run_tests.sh` against Godot 4.6 headless.
**Learning:** `addons/gdUnit4/bin/GdUnitCmdTool.gd` aborts with exit 103 in
headless mode unless `--ignoreHeadlessMode` is passed. Our suites don't
rely on `InputEvent` plumbing, so it's safe.
**Evidence:** `scripts/run_tests.sh`.
**Tag:** godot · gdunit · ci

## 2026-03-23 — `monitor_signals` corrupts autoload singletons in GdUnit4 v6.1.x

**Context:** Writing `tests/unit/signal_bus_connectivity_test.gd`.
**Learning:** Calling `monitor_signals(SignalBus)` on an autoload causes
*"Object-derived class of argument 1 (previously freed)"* errors on the
*next* test in the same suite — the monitor wraps the watched object and
frees the wrapper between cases. Workaround: assert signal contracts via
`get_signal_list()` (signal name + arg names) and round-trip with a local
`Callable` you connect & disconnect yourself.
**Evidence:** `tests/unit/signal_bus_connectivity_test.gd`.
**Tag:** godot · gdunit · autoload

## 2026-03-23 — Godot 4.6 emits `*.uid` files alongside every script

**Context:** `git status` was noisy after running tests / opening project.
**Learning:** Godot 4.6 generates a `script.gd.uid` file next to every
`.gd` script for the new UID-based resource system. These regenerate on
import — ignore them via `*.uid` in `.gitignore`.
**Evidence:** `.gitignore`.
**Tag:** godot · git

## 2026-03-23 — GDExtension `dlopen` errors are non-fatal in CI

**Context:** Running tests in CI without `godotty-node` built.
**Learning:** Godot logs scary `Can't open dynamic library` errors when a
GDExtension dylib is missing, but the engine continues; `TerminalManager`
detects this via `ClassDB.class_get_method_list("TerminalNode2D")` and
falls back to mock mode. Don't `grep ERROR` to gate CI — use the GdUnit4
exit code.
**Evidence:** `project/autoload/terminal_manager.gd`, `.github/workflows/ci.yml`.
**Tag:** godot · gdextension · ci


## 2025-01-XX — Windows: portable_pty DLL init can fail; force mock mode

**Context:** Real terminal backend crashed on Windows during plugin init.
**Learning:** On Windows, force `is_mock_mode = true` until godotty-node ships
a fix. Detection alone is insufficient because `ClassDB` reports the class
present but instantiation fails later.
**Evidence:** commit `6cf2a45` (`fix: force mock terminal on Windows`).
**Tag:** windows · pty · gdextension

## 2025-01-XX — `class_name TerminalManager` conflicts with autoload of same name

**Context:** Adding `class_name` to `terminal_manager.gd`.
**Learning:** Godot rejects a `class_name` that matches an active autoload
singleton's name with a parser error at load time. Either drop the
`class_name` or rename the autoload.
**Evidence:** commit `4ee809d` (`fix: remove class_name TerminalManager`).
**Tag:** godot · gdscript · autoload

## 2025-01-XX — `RichTextLabel` and `ScrollContainer` steal focus from `LineEdit`

**Context:** Terminal input lost focus after every command.
**Learning:** Both `RichTextLabel` (the output) and the surrounding
`ScrollContainer` need `focus_mode = 0` (none), AND the `LineEdit` must
`call_deferred("grab_focus")` after every output append (and after submission
clear), or focus is stolen by the implicit click handling.
**Evidence:** commits `693506a`, `90dca8c`, `bad00be`.
**Tag:** godot · ui · focus

## 2025-01-XX — `write_input(cmd)` without `\n` looks fine but never executes

**Context:** Real PTY mode appeared broken — commands echoed but no output.
**Learning:** A PTY-backed shell needs the literal newline character to
treat input as a submitted line. Always send `cmd + "\n"`.
**Evidence:** PR #4 (`feat: improved ANSI parser…`); see
`_on_text_submitted` in `terminal_view.gd`.
**Tag:** pty · terminal

## 2025-01-XX — ANSI escapes can split across PTY read chunks

**Context:** Garbled colors when shell output came in fast.
**Learning:** Always buffer a partial escape sequence (everything from the
last `\x1b` to end-of-chunk if no final letter seen) and prepend it to the
next chunk. See `_partial_escape` in `terminal_view.gd`.
**Evidence:** PR #4.
**Tag:** ansi · pty · terminal
