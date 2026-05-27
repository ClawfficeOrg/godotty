# Debug Capture Instructions

The code now has debug logging enabled to help diagnose the BBCode and character doubling bugs.

## How to capture debug output:

### Option 1: Run from terminal (recommended)
```bash
cd godotty
godot --path project 2>&1 | tee debug_output.log
```

This will:
- Show the Godot editor/game window
- Print debug messages to your terminal
- Save a copy to `debug_output.log`

### Option 2: Run and watch console
```bash
cd godotty
godot --path project
```

Then watch the terminal output as you type commands or see the prompt appear.

## What to capture:

**Please capture the first ~100 lines after the shell prompt appears**, especially:

1. Lines starting with `[DEBUG _on_output_ready]` — raw shell/PTY output
2. Lines starting with `[DEBUG _append_output]` — processed BBCode
3. Lines starting with `[DEBUG CR]` — carriage return handling

## What I need from you:

Either:
- Paste the first ~100 lines of debug output here, OR
- Share the `debug_output.log` file

Focus on the output from when you:
- First see the prompt appear
- Type a simple command like `ls` and hit Enter
- See the doubled character or visible BBCode tags

## Example of what I'm looking for:

```
[DEBUG _on_output_ready] Raw input: "\\u001b[32mhello\\u001b[0m"
[DEBUG _append_output] BBCode: "[color=#00ff00]hello[/color]"
[DEBUG CR] Detected CR + non-newline. next_ch="h" last_newline=-1
```

This will help me see:
- What ANSI sequences Starship is sending
- What BBCode we're generating
- Whether the character doubling happens at input or during processing
- Why closing tags are appearing as text

Once I see the debug output, I can pinpoint the exact issue and fix it.
