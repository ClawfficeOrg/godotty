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

## 2026-05-27 — `\x` hex escapes in GDScript cause runtime parse error in Godot 4.6.2

**Context:** Writing the first test that loads `terminal_view.gd` (via `preload` of terminal.tscn). The file contained `"\x04"`, `"\x1b"`, `"\x07"`, `"\x08"`, `"\x03"` string literals.
**Learning:** `gdformat` and `gdlint` accept `\xNN` hex escape syntax, but Godot 4.6.2's runtime parser rejects them with `Parse Error: Invalid escape in string`. The file was never loaded by prior tests (which only touched autoloads), so the bug was latent. Always use the `\uXXXX` four-digit Unicode form (e.g. `"\u001b"` for ESC, `"\u0003"` for Ctrl+C, `"\u0004"` for Ctrl+D, `"\u0007"` for BEL, `"\u0008"` for BS). `char(N)` also works.
**Evidence:** `project/scripts/terminal_view.gd` — escape fix in task 1.0.2.
**Tag:** godot · gdscript

## 2026-05-27 — Godot 3-style `disconnect`/`is_connected` causes parse error in Godot 4.x

**Context:** `_exit_tree` in `terminal_view.gd` used `SignalBus.is_connected("output_ready", self, "_on_output_ready")` and `SignalBus.disconnect("output_ready", self, "_on_output_ready")` — the old Godot 3 three-argument signature.
**Learning:** In Godot 4, `is_connected` and `disconnect` only accept a `Callable` as the second argument (`signal.is_connected(callable)`, `signal.disconnect(callable)`). The three-argument string form is a parse error. GdUnit4's scanner surfaces this as `Parse Error: argument 2 should be "Callable" but is "TerminalView"`. This was also latent because the file was never loaded by prior tests.
**Evidence:** `project/scripts/terminal_view.gd:_exit_tree` — fixed in task 1.0.2.
**Tag:** godot · gdscript

## 2026-05-27 — gdlint `max-public-methods` too low for GdUnit4 test suites

**Context:** Writing `tests/unit/terminal_grid_test.gd` with 42 test_ methods.
**Learning:** gdlint's default `max-public-methods` is 20. GdUnit4 test suites
(which must expose every test case as a public `test_*` function) routinely
exceed this. Add `max-public-methods: 100` (or a suitable large number) to
`.gdlintrc` for the project. The existing lower limit is fine for production
code; only test files hit it.
**Evidence:** `.gdlintrc`, `tests/unit/terminal_grid_test.gd`.
**Tag:** gdscript · gdunit · ci



**Context:** Writing `exit_code_test.gd` — need to assert exit code propagation.
**Learning:** `TerminalManager._on_real_shell_exited(code)` receives the PTY
exit code but only prints it; it does not re-emit on a public signal or store it
as a property. To test exit code propagation via the current API, use
`echo $?` in the running shell session and assert the value appears in
`output_received`. Adding a `shell_exited(code)` signal to TerminalManager
would require touching the autoload (Hard Stop) — defer to a follow-up spec.
**Evidence:** `project/autoload/terminal_manager.gd:_on_real_shell_exited`,
`tests/integration/real/exit_code_test.gd`.
**Tag:** godot · pty · terminal

## 2026-05-27 — `spawn_shell()` emits `shell_started` synchronously; `await` misses it

**Context:** Writing `before_test()` for real-mode integration base class.
**Learning:** `_real_spawn_shell()` calls `shell_started.emit()` synchronously
before returning. `await TerminalManager.shell_started` placed *after*
`spawn_shell()` will never receive the signal. Use a fixed settle delay
(`create_timer(0.3).timeout`) instead of awaiting the signal.
**Evidence:** `project/autoload/terminal_manager.gd:_real_spawn_shell`,
`tests/integration/real/__init__.gd:before_test`.
**Tag:** godot · gdscript · pty

## 2026-05-27 — GdUnit4 runs base classes with no tests as empty suites (0 tests, 0 failures)

**Context:** `tests/integration/real/__init__.gd` extends `GdUnitTestSuite` but
has no `test_*` methods. GdUnit4 discovers it when scanning the directory.
**Learning:** GdUnit4 instantiates the class, finds no test methods, reports
"0 tests, 0 failures" — not an error. Safe to use as an inheritance base inside
the scanned directory.
**Evidence:** `tests/integration/real/__init__.gd`.
**Tag:** godot · gdunit



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
