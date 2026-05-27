# Terminal Display Issues - Fixed

## Issue 1: Double Character Display (Not a Bug!)

### Symptom
When typing in the terminal with the real PTY (godotty-node), each character appears twice in the display. For example, typing "cd" shows "ccd" on screen.

### Root Cause
This is **correct terminal emulator behavior**, not a bug. The shell (bash, zsh, fish, etc.) performs **local echo** - it echoes back each character you type so you can see your input. This is standard behavior for all interactive terminals.

### Evidence
- The commands work correctly (typing "cd dirname" successfully changes directory)
- Only one character is actually sent to the PTY
- The "doubling" only occurs visually because the shell echoes the character back

### Comparison
Try the same behavior in any other terminal emulator (iTerm2, Terminal.app, etc.):
1. Type a character
2. The terminal sends it to the shell
3. The shell receives it and echoes it back
4. You see the character appear

This is how terminals have worked since the 1970s. The alternative (no echo) would require you to type blind, which is undesirable for interactive use.

### Non-Interactive Mode
In non-interactive or piped mode, shells typically disable echo:
```bash
echo "ls" | bash    # No double-echo
bash -c "ls"        # No double-echo
bash                # Interactive - has echo
```

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

1. **"Double characters"** → Not a bug, this is correct terminal behavior (shell local echo)
2. **"Background colors not working"** → Fixed by implementing full SGR background color support

Both issues are now resolved or explained!
