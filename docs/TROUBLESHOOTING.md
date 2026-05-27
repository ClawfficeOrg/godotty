# Troubleshooting

## "Could not find type" Parse Errors on Startup

### Symptoms
```
SCRIPT ERROR: Parse Error: Could not find type "TerminalTheme" in the current scope.
SCRIPT ERROR: Parse Error: Could not find type "TerminalKeymap" in the current scope.
SCRIPT ERROR: Parse Error: Could not find type "TerminalGrid" in the current scope.
ERROR: Failed to instantiate an autoload, script 'res://autoload/terminal_manager.gd' does not inherit from 'Node'.
```

### Root Cause
This happens when:
1. The project is already open in Godot
2. You try to run it again from the command line (`godot .`)
3. Godot attempts a hot-reload of scripts
4. Script dependencies load in the wrong order

The `class_name` declarations (TerminalTheme, TerminalKeymap, etc.) haven't been registered yet when the autoload tries to reference them.

### Solution

**Option 1: Clean Restart (Recommended)**
```bash
# From the godotty directory:
./scripts/clean_restart.sh
```

This script:
- Kills any running Godot instances
- Clears the `.godot` cache directory
- Opens the project fresh

**Option 2: Manual Steps**
1. Close all Godot instances completely (don't just close the window)
2. Delete `project/.godot` directory
3. Open the project: `cd project && godot .`

**Option 3: Editor Restart**
If you're in the Godot editor:
1. Project → Reload Current Project
2. If that doesn't work: close Godot, delete `.godot`, reopen

### Prevention
- Don't run `godot .` while the project is already open
- Use the clean restart script during development
- If you modify `class_name` declarations, always do a clean restart

---

## Invalid Access to 'is_mock_mode' on Nil

### Symptoms
```
SCRIPT ERROR: Invalid access to property or key 'is_mock_mode' on a base object of type 'Nil'.
```

### Root Cause
The `TerminalManager` autoload hasn't finished initializing when another script tries to access its properties.

### Solution
This was fixed in commit `cdf85ec` by adding:
- `await get_tree().process_frame` in `main.gd` before accessing autoloads
- Null checks before accessing `TerminalManager` properties

If you still see this error, make sure you're on the latest commit.

---

## First Character Doubling

### Symptoms
- Type `cd` → see `ccd`
- Type `ls` → see `lls`
- Type `echo hi` → see `eecho hi`

### Solution
Fixed in commit `c37069b` by properly handling carriage return (`\r`) for shell line rewrites.

Pull the latest changes: `git pull origin master`

---

## Background Colors Not Working

### Symptoms
ANSI background color codes (like `\e[41m` for red background) don't render.

### Solution
Fixed in commit `b60907c` by implementing full SGR background color support (codes 40-47, 49, 100-107, 48;5;N, 48;2;R;G;B).

Test with: `./scripts/test_bgcolor.sh` (from within the terminal)

---

## GDExtension Crash (SIGTRAP)

### Symptoms
```
Initialize godot-rust (API v4.6.stable.official, runtime v4.6.2.stable.official, safeguards balanced)
handle_crash: Program crashed with signal 5
```

### Root Cause
The godotty-node extension was built against a different Godot API version than the running engine, or there's a thread-safety issue.

### Solution

**Temporary Workaround:**
Force mock mode (disables the extension):
```bash
GODOTTY_FORCE_MOCK=1 godot .
```

**Permanent Fix:**
Rebuild godotty-node against your Godot version:
```bash
cd godotty-node/rust
cargo build --release
cp target/release/libgodotty_node.{dylib,so,dll} ../path/to/godotty/project/addons/godotty-node/bin/
```

See the [previous troubleshooting thread](zed:///agent/thread/7b9784bb-a6e3-4652-b731-8c04fec32fcd) for full details.

---

## Unicode Parsing Errors (Cosmetic)

### Symptoms
```
Unicode parsing error: Invalid unicode codepoint (25c0), cannot represent as ASCII/Latin-1
Unicode parsing error: Invalid unicode codepoint (25b6), cannot represent as ASCII/Latin-1
```

### Root Cause
Your shell prompt (Starship) uses Unicode glyphs (◀ U+25C0, ▶ U+25B6) that Godot's console logger can't represent in ASCII/Latin-1.

### Solution
This is **cosmetic only** and doesn't affect terminal functionality. The glyphs display correctly in the terminal view itself.

To suppress these warnings, the godotty-node Rust code should avoid logging raw PTY output via `godot_print!()` and only emit via GDScript signals.

---

## General Troubleshooting Steps

1. **Always start with a clean restart**: `./scripts/clean_restart.sh`
2. **Check you're on the latest commit**: `git pull origin master`
3. **Rebuild the GDExtension if needed** (after Godot updates)
4. **Use mock mode for UI-only testing**: `GODOTTY_FORCE_MOCK=1 godot .`
5. **Check the console for errors**: Look for parse errors, crashes, or warnings

Still stuck? Check existing issues or open a new one with:
- Full error output
- Godot version (`godot --version`)
- OS and architecture
- Steps to reproduce
