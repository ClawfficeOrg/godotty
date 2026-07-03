# Project Learnings — INDEX

Append-only log of non-obvious things the agent has learned.
**Newest at top.** Each entry: date, one-line summary, evidence/links.

## 2026-07-03 — ConPTY spawn does not search PATH; forward slashes break cmd.exe argv0

**Context:** `spawn_shell_with("cmd.exe", ...)` reported success (process handle valid, `running=true`) but produced zero output forever. Absolute backslash path worked.
**Learning:** Three separate spawn traps on Windows ConPTY: (1) bare executable names are not PATH-resolved — the spawn silently produces a dead session; (2) forward slashes in the executable path make cmd.exe parse `/W...` from its own argv0 as switches; (3) failure mode is silent — no error, no EOF, just no bytes. Resolve to an absolute native path before spawning (`resolve_shell_path` in godotty-node).
**Evidence:** godotty-node commit `01fc794`.
**Tag:** windows · conpty · rust

## 2026-07-03 — ConPTY defers first output ~3 s (DA1 query timeout); \r is Enter, \n just types

**Context:** Real integration tests timed out even though the shell was alive and the manager signal chain was correct.
**Learning:** (1) ConPTY sends device queries (`ESC[c` etc.) at spawn and holds the first output flood ~3 s waiting for a response — settle delays and test windows must account for it. (2) A bare `\n` written to ConPTY types the text into the line buffer without executing; only `\r` is Enter. Unix ICRNL maps CR→NL, so `\r` is the correct cross-platform Enter. (3) ConPTY wraps output lines in OSC title + cursor-move sequences — test predicates must not anchor at line start (`^42` never matches; `42\r?\n` does). (4) Windows PowerShell 5.1 cold-starts ~10 s under headless ConPTY.
**Evidence:** `tests/integration/real/__init__.gd`, `lib/rust/examples/pty_smoke.rs`.
**Tag:** windows · conpty · testing

## 2026-07-03 — GDScript lambdas capture locals by value; signal callbacks can't write to them

**Context:** `run_and_await` set `done = true` inside an output-signal lambda; the outer polling loop never saw it and every real test timed out silently.
**Learning:** GDScript 4 lambdas capture surrounding locals **by value**. Assigning to a captured `bool`/`String` mutates the lambda's private copy only. To communicate from a callback to the enclosing scope, share a reference type (Dictionary/Array) or use a member variable.
**Evidence:** `tests/integration/real/__init__.gd` `run_and_await` state Dictionary.
**Tag:** gdscript · godot

## 2026-07-03 — Blocking OS.execute in _ready flakes timing tests; .gdignore hides submodule from res://

**Context:** ShellDetector probed `where`/`which` on every TerminalView `_ready`; the bell flash test measured 0.2 s where 0.1 s was expected. Separately, `.gdextension` paths pointing into the submodule never loaded.
**Learning:** (1) `OS.execute` blocks the main thread (~100 ms per probe) — cache detection results for the process lifetime, never probe per-instance. (2) A `.gdignore` file makes Godot ignore the whole directory for `res://` — GDExtension binaries inside a `.gdignore`'d submodule are unloadable; install them outside (e.g. `bin/<platform>/`).
**Evidence:** `shell_detector.gd` `_cached_profiles`; `godotty-node.gdextension` bin/ paths.
**Tag:** godot · testing · gdextension

## 2026-07-03 — Godot 4.6.2 GDScript parser rejects CRLF line endings on Windows

**Context:** Fresh checkout on Windows with `core.autocrlf=true`. Every `.gd` file with CRLF caused parse errors.
**Learning:** Unlike Godot 3.x, Godot 4.6.2's GDScript parser does NOT accept CRLF (`\r\n`) line endings. Files with `^M$` fail with "Parse Error: Could not parse global class" or "Identifier not declared" depending on context. Fix: either set `core.autocrlf=false` and use LF-only, or add `.gitattributes` with `*.gd text eol=lf` to force LF on checkout.
**Evidence:** `.gitattributes`, `scripts/run_tests.sh` CRLF fix.
**Tag:** godot · gdscript · windows

## 2026-07-03 — Signal forwarding pattern bridges base-class signals to global bus without coupling

**Context:** Refactoring `TerminalManagerBase` shared between autoload and per-tab node (§3.4).
**Learning:** The cleanest way to handle near-identical functions that differ only by SignalBus emissions is to:
1. Have the base class emit all instance signals (output_received, shell_started, etc.).
2. The autoload subclass connects to its OWN signals in `_ready` via signal forwarding functions that re-emit on SignalBus.
3. No virtual methods, no overrides needed for the SignalBus bridge.
4. The `_check_addon_availability` function needed a new `addon_availability_changed` signal on the base, since it previously emitted directly on SignalBus.
**Evidence:** `project/autoload/terminal_manager.gd` — `_ready()` connects 5 forwarding functions; `project/scripts/terminal_manager_base.gd`.
**Tag:** godot · gdscript · signals · refactoring

## 2026-07-03 — Scrollback trim must adjust selection coordinates or selection drifts

**Context:** Fixing §3.5 — selection coordinates drift when `_enforce_scrollback_limit` removes old lines.
**Learning:** When trimming lines from the front of a scrollback buffer, all selection row indices must be decremented by the number of removed lines. If the entire selection falls off (new_end_y < 0), reset to (-1,-1). The `_update_selection_overlay()` call after adjustment hides the overlay automatically when selection is cleared.
**Evidence:** `project/scripts/terminal_view.gd:_enforce_scrollback_limit` — selection adjustment block.
**Tag:** godot · gdscript · selection · scrollback

## 2026-07-03 — `.gdextension` files with `res://../../` relative paths don't resolve when embedded as submodule

**Context:** Adding godotty-node as a submodule at `project/addons/godotty-node/lib/`.
**Learning:** The submodule's `.gdextension` file at `lib/project/godotty-node.gdextension` uses `res://../../rust/target/...` paths to reference Rust build output. These paths would resolve to `res://addons/godotty-node/rust/target/...` (one level outside the submodule) instead of the correct `res://addons/godotty-node/lib/rust/target/...`. Fix: keep godotty's own `.gdextension` with explicit `res://addons/godotty-node/lib/rust/target/...` library paths, pointing into the submodule.
**Evidence:** `project/addons/godotty-node/godotty-node.gdextension`.
**Tag:** godot · gdextension · submodule



## 2026-05-27 — BBCode tags must follow LIFO nesting when changing FG color with active BG

**Context:** Visible `[/bgcolor]`, `[/color]` tags in Starship prompts. Tags rendered as plaintext.

**Root cause:**
- Starship emits compound SGR like `[48;2;R;G;B;38;2;R;G;B;m` (set BG, then change FG in same seq).
- Our SGR handler processed sequentially: open FG, open BG, close FG, open new FG.
- Generated BBCode: `[color=A][bgcolor=B][/color][color=C]`
- The `[/color]` closes a tag opened **before** the `[bgcolor]`, violating LIFO nesting.
- RichTextLabel parsed the orphaned closing tags but rendered them as plaintext.

**Fix:** `_close_fg()` now closes tags in LIFO order: close BG, close FG, reopen BG, open new FG.
Result: `[color=A][bgcolor=B][/bgcolor][/color][bgcolor=B][color=C]` (properly nested).

**Also fixed:** Check if color is changing before emitting close+open pairs (all SGR color codes).

**Lesson:** When generating nested markup (BBCode, HTML, etc.) from stateful commands (ANSI SGR),
always close tags in LIFO order. Maintain a stack or explicitly handle nesting when changing
inner attributes while outer ones are active.

**Evidence:** `project/scripts/terminal_view.gd::_close_fg()` lines 993-1011, SGR handlers lines
904-972. Debug output from MCP `run_project` showed malformed BBCode before fix, proper nesting after.

**Tag:** godot · gdscript · bbcode · ansi · sgr · terminal-rendering · starship · nesting

---

## 2026-05-27 — `_close_all_tags()` must clear all state vars, not just bold/underline

**Context:** User reported visible BBCode tags (`[/bgcolor]`, `[/color]`, `[/b]`) in Starship prompt.

**Root cause:**
- `_close_all_tags()` emits `[/bgcolor]` and `[/color]` closing tags, but did **not** reset
  `_current_bg` and `_current_fg` to empty strings.
- It correctly reset `_current_bold = false` and `_current_underline = false`.
- This inconsistency caused duplicate closing tags to be emitted on subsequent color changes
  or SGR 0 resets.
- Orphaned closing tags (no matching opening tag) are parsed by RichTextLabel but rendered
  as plaintext because they don't balance with any open tag.

**Fix:** Set `_current_bg = ""` and `_current_fg = ""` after appending the closing tags.

**Lesson:** When state-tracking functions emit BBCode tags, **always** update the state vars
in the same block. The pattern must be consistent: emit tag, then clear/update state.

**Evidence:** `project/scripts/terminal_view.gd::_close_all_tags()` lines 956-970 — fixed 2026-05-27.

**Tag:** godot · gdscript · bbcode · ansi · terminal-rendering · starship

---

## 2026-05-27 — ResourceLoader.load() after spawn_shell() reliably triggers godot-rust cross-thread SIGTRAP

**Context:** Real PTY mode crashing with signal 5 after rebuilding godotty-node against Godot 4.6
(godot-rust `safeguards balanced`). The crash happened at startup right after "shell spawned".
**Learning:** godot-rust `safeguards balanced` asserts that all Godot API calls happen on the main
thread. The godotty-node Rust extension emits `output_received` from its PTY reader background
thread -- a threading bug in the extension. This races the main thread whenever the main thread
is busy doing anything after `spawn_shell()`. The race is usually very tight (Starship's prompt
arrives in < 1 ms), so it often doesn't trigger. But adding `ResourceLoader.load()` for the
JetBrains Mono Nerd Font (2.8 MB TTF) AFTER `spawn_shell()` in `apply_font_settings()` blocked
the main thread for ~10-50 ms -- turning an occasional race into a reliable SIGTRAP.
Fix (GDScript side): load the font in `_ready()` BEFORE `_initialize_terminal()` / `spawn_shell()`.
Do NOT call `ResourceLoader.load()` or any other blocking call between `spawn_shell()` and the
first output_received emission (approximately the first frame tick).
Real fix (Rust side): emit `output_received` from the main thread only, using `call_deferred` or
a thread-safe queue polled in `_process()`. File against godotty-node.
**Evidence:** `project/scripts/terminal_view.gd:_ready` and `apply_font_settings` -- fixed 2026-05-27.
**Tag:** godot · godot-rust · gdextension · threading · pty · macos

## 2026-05-27 — ZLE/readline `\x1b[J` (ED mode 0) in primary mode wipes output one frame after it appears

**Context:** Real PTY mode — typing `ls`, hitting Enter, watching the file list appear for ~1 frame then vanish.
**Learning:** Zsh's Z Line Editor (and bash readline) emit `\x1b[J` (CSI J with no parameters = Erase
Display mode 0, "erase from cursor to end of screen") each time they redraw the prompt after a
command completes. In a real terminal with a fixed viewport this is harmless — it erases blank
space below the current cursor row. In Godotty's streaming RichTextLabel model there is no fixed
viewport, so `_ansi_to_bbcode` was incorrectly treating mode-0 the same as mode-2 (`\x1b[2J`)
and calling `call_deferred("_clear_output")`. The deferred clear runs the frame AFTER the output
was appended, causing the one-frame flash.
Fix: only call `_clear_output()` on mode 2 (explicit full-screen clear, i.e. the `clear` command
or Ctrl+L). Mode 0 and mode 1 are no-ops in primary streaming mode.
**Evidence:** `project/scripts/terminal_view.gd:_ansi_to_bbcode` `J` case — fixed 2026-05-27.
**Tag:** godot · gdscript · ansi · pty

## 2026-05-27 — Unicode parsing warnings for U+25C0/U+25B6 come from Starship prompt via PTY, not GDScript files

**Context:** Startup log shows `Unicode parsing error: Invalid unicode codepoint (25c0/25b6)` apparently
before the "GodottyNode GDExtension detected" line.
**Learning:** The characters U+25C0 (◀) and U+25B6 (▶) are Starship prompt glyphs. They are not in
any `.gd` or resource file. The apparent log ordering is a flush/buffering artifact (Godot's stderr
flushes before GDScript `print()` calls appear). What actually happens: the shell spawns, Starship
renders its prompt (containing ◀ and ▶) into the PTY, the godotty-node Rust extension receives that
output and calls `godot_print!()` with the raw bytes, and Godot's print path fails to represent
those codepoints in a Latin-1 console environment, emitting the "Unicode parsing error" warnings.
They are non-fatal cosmetic log noise. The fix sits in the godotty-node Rust crate: avoid
`godot_print!()` on raw PTY output and emit only via the `output_received` GDScript signal.
**Evidence:** Characters absent from all project `.gd` files; Starship is the active shell prompt.
**Tag:** godot · godot-rust · gdextension · unicode · pty · starship

## 2026-05-27 — godot-rust extension built against Godot 4.3 API crashes (SIGTRAP) on Godot 4.6.2 runtime — RESOLVED

**Context:** Running Godotty with godotty-node dylib present. The log said
`Initialize godot-rust (API v4.3.stable.official, runtime v4.6.2.stable.official)` then crashed
with signal 5 immediately after `spawn_shell()` returned.
**Learning:** godot-rust uses static binding; mismatching API and runtime versions can compile
(the extension loads) but produce a SIGTRAP the moment a changed vtable entry is touched.
GDScript cannot catch a native signal 5 — the process dies. Two mitigations:
1. Set `GODOTTY_FORCE_MOCK=1` in the environment to bypass the extension entirely (now
   wired into both `TerminalManager` autoload and `TerminalManagerNode`); use this while waiting
   for a rebuilt dylib.
2. Rebuild godotty-node locally with `cargo build` against the Godot 4.6 header set, then
   replace `project/addons/godotty-node/bin/macos/libgodotty_node.dylib`.
**Resolution:** Rebuilt godotty-node against Godot 4.6 on 2026-05-27. Real PTY mode stable.
**Evidence:** crash output `handle_crash: Program crashed with signal 5`;
`project/autoload/terminal_manager.gd:_check_addon_availability`.
**Tag:** godot · godot-rust · gdextension · macos

## 2026-05-27 — `_load_and_apply_theme("")` resolves to `res://resources/themes/.tres` (no file)

**Context:** Opening the project; `TerminalSettings.selected_theme_name` starts as `""` (static
var default). `_initialize_terminal` calls `_load_and_apply_theme("")`, slug becomes `""`, path
becomes `res://resources/themes/.tres` which does not exist.
**Learning:** Always guard `_load_and_apply_theme` against empty input — default to
`BUNDLED_THEME_NAMES[0]` ("Default"). An `if tname.is_empty(): tname = BUNDLED_THEME_NAMES[0]`
check at the top of the function is sufficient. `ResourceLoader.load` on a bad path logs three
consecutive ERROR lines and returns null (safe), but the errors pollute the log and confuse
debugging sessions.
**Evidence:** `project/scripts/terminal_view.gd:_load_and_apply_theme` — fixed 2026-05-27.
**Tag:** godot · gdscript · resources

## 2026-05-27 — OSC sequences (ESC]) are silently dropped by the `bracket_pos == -1` guard in `_ansi_to_bbcode`

**Context:** Implementing task 3.0.4 — OSC 0/2 tab-title sequences.
**Learning:** The early-exit guard `var bracket_pos := rest.find("["); if bracket_pos == -1: ...`
was intended to buffer incomplete CSI sequences (ESC[), but also caught ANY escape sequence
that doesn't contain `[`, including fully-complete OSC sequences (ESC]). This silently discarded
all OSC sequences. Fix: change guard to `if rest.length() == 1 or (rest[1] == "[" and rest.length() == 2):`
so only a bare ESC or an ESC[ with no further content is buffered.
**Evidence:** `project/scripts/terminal_view.gd:_ansi_to_bbcode` — task 3.0.4.
**Tag:** godot · gdscript · ansi · osc



**Context:** Implementing task 3.0.2 — a custom tab bar widget with `class_name TabBar`.
**Learning:** Godot 4 exposes `TabBar` and `TabButton` as native (C++) classes. A GDScript file with
`class_name TabBar` triggers `Parse Error: Class "TabBar" hides a native class` and then causes all
calls to `add_tab(...)` to fail with "argument 2 should be Texture2D" (the native method signature).
Fix: prefix custom class names — e.g. `TerminalTabBar` / `TerminalTabButton`.
**Evidence:** `project/scripts/tab_bar.gd`, `project/scripts/tab_button.gd` — task 3.0.2.
**Tag:** godot · gdscript

## 2026-05-27 — gdlint `class-definitions-order` requires public `@onready var` before private `_`-prefixed ones

**Context:** Adding `@onready var search_bar: SearchBar = $SearchBar` after existing private `@onready var _theme_menu`, `_font_option`, `_font_spinbox` in `terminal_view.gd` (task 2.2.1).
**Learning:** gdlint's `class-definitions-order` rule enforces public declarations before private (underscore-prefixed) declarations within each declaration class (var, onready var, etc.). A public `@onready var` placed after private `@onready var _xxx` triggers "Definition out of order in global scope". Fix: move all public onready vars before the private ones.
**Evidence:** `project/scripts/terminal_view.gd` — task 2.2.1.
**Tag:** gdscript · gdlint



**Context:** Adding `BUNDLED_THEME_NAMES: Array[String]` constant to `TerminalSettings` after existing `static var` declarations (task 2.0.4).
**Learning:** gdlint's `class-definitions-order` rule requires `const` definitions to appear before `var`/`static var` definitions in class scope. Placing a `const` after any `var` triggers "Definition out of order in global scope". Fix: always declare all `const` blocks first, then `var`/`static var` blocks.
**Evidence:** `project/scripts/terminal_settings.gd` — task 2.0.4.
**Tag:** gdscript · gdlint

## 2026-05-27 — `DisplayServer.clipboard_get()` returns empty string in Godot headless mode

**Context:** Writing clipboard paste tests (task 1.4.3) — calling `DisplayServer.clipboard_set("hello")` then `clipboard_get()` in headless Godot returned "".
**Learning:** Godot's headless DisplayServer does not persist clipboard data between `clipboard_set` and `clipboard_get` calls in the same process. Tests that need to verify the clipboard read path must use a `_clipboard_override` var on TerminalView (set before the key event) rather than relying on the system clipboard. Production code reads from `DisplayServer.clipboard_get()` normally.
**Evidence:** `project/scripts/terminal_view.gd:_get_clipboard_text`, `tests/unit/terminal_view_paste_test.gd` — task 1.4.3.
**Tag:** godot · gdscript · testing · clipboard

## 2026-05-27 — Godot 4.6 treats `min()` return as Variant — always annotate the type

**Context:** Adding `get_selected_text()` in `terminal_view.gd` with `var end_c := min(...)`.
**Learning:** Godot 4.6's GDScript compiler treats `min(a, b)` as returning `Variant` (since it's a polymorphic built-in), so `:=` inference produces a Variant variable. The engine treats this as a warning elevated to error (`"variable type inferred as Variant"`), which prevents the script from loading. Fix: use explicit typing — `var end_c: int = min(max_col + 1, line.length())`.
**Evidence:** `project/scripts/terminal_view.gd:277` — task 1.4.2.
**Tag:** godot · gdscript



**Context:** Writing `test_paste_bare_has_no_start_marker_when_mode_off` in the bracketed paste test suite.
**Learning:** `GdUnitStringAssertImpl` in GdUnit4 v6.1.x does not expose `does_not_start_with` or `does_not_end_with`. Calling them causes a runtime script error ("Nonexistent function"). Use `assert_str(...).is_equal(expected_value)` to prove absence of markers — an exact equality check is a stronger assertion anyway.
**Evidence:** `tests/unit/terminal_view_paste_wrap_test.gd` — task 1.3.2.
**Tag:** gdscript · gdunit · testing

## 2026-05-27 — Godot 4 signal Callable disconnect requires the exact same Callable reference

**Context:** Connecting `SignalBus.terminal_resized` to `_on_terminal_resized` in TerminalManager's `_ready()`, then disconnecting in `_exit_tree()`.
**Learning:** In Godot 4, `signal.connect(callable)` and `signal.disconnect(callable)` must receive the *same* Callable object (i.e., the result of `func_ref` / method Callable). Passing a newly constructed `Callable(self, "_on_terminal_resized")` in `_exit_tree` when you used `self._on_terminal_resized` in `_ready` will fail if they don't compare equal. The safe pattern: use the method reference form (`self._on_terminal_resized`) in both calls so Godot can compare them by object+method identity.
**Evidence:** `project/autoload/terminal_manager.gd` — task 1.2.2.
**Tag:** godot · gdscript · signals

Format:

    ## YYYY-MM-DD — short title
    **Context:** what we were doing
    **Learning:** the thing
    **Evidence:** commit / PR / line ref
    **Tag:** godot | gdscript | pty | ci | git | windows | macos | linux

---

## 2026-05-27 — gdlint `class-definitions-order` rejects computed properties after private vars

**Context:** Adding `cursor_row`/`cursor_col` as GDScript 4 computed properties (var with getter block) after the existing private vars `_cols`, `_rows`, `_cells` in `terminal_grid.gd`.
**Learning:** gdlint flags any `var name: Type:` (property with getter/setter block) as "Definition out of order in global scope (class-definitions-order)" when it appears *after* underscore-prefixed private vars. Fix: move the computed properties to come before the private vars, or (simpler) use plain public vars instead of getter blocks — they avoid the ordering issue entirely.
**Evidence:** `project/scripts/terminal_grid.gd` — task 1.0.3.
**Tag:** gdscript · gdlint

## 2026-05-27 — gdlint rejects uppercase letters anywhere in test function names

**Context:** Naming test functions after CSI sequences (e.g., `test_csi_H_...`, `test_csi_A_...`).
**Learning:** The `function-name` pattern `'(_on_)?_?[a-z][a-z0-9]*(_[a-z0-9]+)*'` requires entirely lowercase identifiers. Uppercase letters anywhere in the name cause a "Function name … is not valid" lint error. Use lowercase equivalents: `test_csi_h_...`, `test_csi_a_...`.
**Evidence:** `tests/unit/terminal_view_ansi_cursor_test.gd` — task 1.0.3.
**Tag:** gdscript · gdlint · testing

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
