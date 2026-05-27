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

**The Real Fix: Open in Editor First**

Godot needs to scan and register `class_name` declarations before the project can run. This happens when you open the project in the **Godot Editor** (not when running directly).

**Steps:**
1. Kill any running Godot instances
2. Delete `project/.godot` directory
3. Open the project in the **editor**: `godot --editor project/project.godot`
4. Wait for the editor to fully load and scan scripts (bottom-right shows "ScanSources")
5. Once scanning is complete, you can run the project

**Quick Command:**
```bash
cd godotty
./scripts/clean_cache.sh
cd project
godot --editor project.godot
# Wait for editor to load, then press F5 to run
```

**Why This Happens:**
Godot 4.6 requires the editor to scan and cache `class_name` declarations in `.godot/global_script_class_cache.cfg`. When you run the project directly (`godot .`) without opening the editor first, this cache doesn't exist, causing autoloads to fail parsing.

**Option 2: Run After Editor Scan**
Once the editor has scanned the project (step 3-4 above), you can close it and run from command line:
```bash
cd project
godot .  # Now works because .godot cache exists
```

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
