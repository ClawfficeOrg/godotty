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
