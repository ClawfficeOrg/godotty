# Terminal Display Issues - Fixed

## Issue 1: First Character Doubling (FIXED)

### Symptom
When typing in the terminal with the real PTY (godotty-node), the **first character** of each command appeared doubled:
- Type `cd` → display showed `ccd`
- Type `ls` → display showed `lls`  
- Type `echo "hello"` → display showed `eecho "hello"`

The commands executed correctly (only one character was sent), but the visual display was wrong.

### Root Cause
The ANSI parser was **ignoring carriage return** (`\r`, ASCII 13) characters completely. 

When you type in an interactive shell, the shell uses readline/ZLE for line editing. After each keystroke, the shell:
1. Sends `\r` (carriage return) to move cursor to column 0
2. Redraws the entire input line
3. Positions the cursor

Because we ignored `\r`, the redrawn line was **appended** instead of **replacing** the current line. This caused the first character (and the prompt) to appear twice.

### Why Only The First Character?
The doubling appeared on the first character because:
1. Initial state: `$ ` (prompt)
2. User types 'c'
3. Shell sends: `\r$ c` (move back, redraw with new char)
4. We ignored `\r`, appended `$ c` → result: `$ $ c` (looks like `$ cc`)
5. User types 'd'  
6. Shell sends: `\r$ cd` (move back, redraw whole line)
7. We ignored `\r`, appended `$ cd` → result: `$ $ c$ cd`
8. But the previous line was already trimmed, so effectively: `$ ccd`

Actually, **every character redraw had the problem**, but it manifested most visibly on the first character.

### Fix Applied
**Commit:** `fix(ansi): handle carriage return for line rewrites`

Implemented proper `\r` handling in the ANSI parser:

```gdscript
elif ch == "\r":
    # Carriage return: move cursor to start of line.
    if i + 1 < input.length():
        var next_ch := input[i + 1]
        if next_ch == "\n":
            # \r\n sequence - just skip the \r, emit \n next iteration
            i += 1
            continue
        elif next_ch != "\u001b":  # Not an escape sequence
            # Shell is rewriting the current line. Remove everything after
            # the last newline from output (so the rewrite replaces it).
            var last_newline := output.rfind("\n")
            if last_newline != -1:
                output = output.substr(0, last_newline + 1)
            else:
                # No newline yet - clear entire output buffer
                output = ""
    i += 1
    continue
```

**Logic:**
- If `\r` is followed by `\n`: treat as Windows line ending, skip the `\r`
- If `\r` is followed by printable text: remove the current line from the output buffer
- If `\r` is followed by an escape sequence: let the escape handler deal with it

This allows the shell's line rewrites to **replace** the current line instead of appending.

### Testing
Manual testing in the real PTY terminal:
- Type commands character by character
- Verify no character doubling
- Verify readline features work (backspace, arrow keys, history)
- Verify output from commands displays correctly

## Issue 2: Background Colors Not Working (FIXED)

### Symptom
ANSI background color codes (like `\e[41m` for red background) were not rendering - text appeared with default background only.

### Root Cause
The ANSI parser in `terminal_view.gd` was tracking background color state (`_current_bg`) but never emitting the corresponding BBCode `[bgcolor=...]` tags.

### Missing Implementations
- SGR 40-47: Standard background colors (black through white)
- SGR 49: Reset background to default
- SGR 100-107: Bright background colors
- SGR 48;5;N: 256-color background (xterm palette)
- SGR 48;2;R;G;B: True-color RGB background
- `_close_bg()` function to properly close bgcolor tags
- `_close_all_tags()` did not reset background

### Fix Applied
**Commit:** `feat(ansi): implement ANSI background color rendering`

Added full support for all ANSI background color modes:

```gdscript
# Standard backgrounds (40-47)
40, 41, 42, 43, 44, 45, 46, 47:
    result += _close_bg()
    _current_bg = _indexed_color(code - 40, false)
    result += "[bgcolor=%s]" % _current_bg

# Reset background (49)
49:
    result += _close_bg()
    _current_bg = ""

# Bright backgrounds (100-107)
100, 101, 102, 103, 104, 105, 106, 107:
    result += _close_bg()
    _current_bg = _indexed_color(code - 100 + 8, false)
    result += "[bgcolor=%s]" % _current_bg

# 256-color background (48;5;N)
48:
    if idx + 2 < codes.size() and int(codes[idx + 1]) == 5:
        result += _close_bg()
        var color_idx := int(codes[idx + 2])
        _current_bg = _xterm256_hex(color_idx)
        result += "[bgcolor=%s]" % _current_bg
        idx += 2

# RGB background (48;2;R;G;B)
    elif idx + 4 < codes.size() and int(codes[idx + 1]) == 2:
        var r := int(codes[idx + 2])
        var g := int(codes[idx + 3])
        var b := int(codes[idx + 4])
        result += _close_bg()
        _current_bg = "#%02x%02x%02x" % [r, g, b]
        result += "[bgcolor=%s]" % _current_bg
        idx += 4
```

Also implemented `_close_bg()` function:
```gdscript
func _close_bg() -> String:
    if not _current_bg.is_empty():
        _current_bg = ""
        return "[/bgcolor]"
    return ""
```

And updated `_close_all_tags()` to reset background:
```gdscript
if not _current_bg.is_empty():
    r += "[/bgcolor]"
```

### Testing
Created comprehensive test suite: `tests/unit/terminal_view_bgcolor_test.gd`
- Tests all SGR background modes (40-47, 49, 100-107, 48;5;N, 48;2;R;G;B)
- Tests combined foreground + background
- Tests background reset with SGR 0
- Tests sequential background color changes

Created manual test script: `scripts/test_bgcolor.sh`
- Run it in the Godotty terminal to visually verify all background colors render correctly
- Usage: `./scripts/test_bgcolor.sh` from within the terminal emulator

### Verification
Background colors now work correctly for:
- Shell prompts with custom backgrounds (Starship, Powerlevel10k, etc.)
- CLI tools like `bat`, `exa`, `delta` that use background colors for syntax highlighting
- ANSI art and colored output from any program

---

## Summary

1. **"First character doubling"** → Fixed by properly handling `\r` (carriage return) for line rewrites
2. **"Background colors not working"** → Fixed by implementing full SGR background color support

Both issues are now resolved!
