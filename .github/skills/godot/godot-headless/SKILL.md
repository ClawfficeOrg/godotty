---
name: godot-headless
description: Run Godot from the command line for CI, tests, builds
when_to_use: Writing CI, debugging a test runner, or scripting a build
---

# Godot Headless

Use the `--headless` flag to run Godot without a window. Always pair with
`--quit` (one-shot) or `--quit-after N` (run N frames then exit).

## Common invocations

### Import / re-import resources (CI cold start)
```sh
godot4 --headless --path project --import
```

### Run a scene then exit
```sh
godot4 --headless --path project scenes/main.tscn --quit-after 100
```

### Run GdUnit4 tests (after install)
```sh
godot4 --headless --path project \
  -s addons/gdUnit4/bin/GdUnitCmdTool.gd \
  -a -c -rd ../tests
```

## Gotchas

- **First headless run after a clean clone always errors out** with
  "no UID detected" or similar. The fix: run `--import` once, then your
  real command. CI must do this.
- `--path` takes the **directory containing project.godot**, not the
  project.godot file itself.
- Exit code semantics: Godot returns 0 on success, 1 on script error.
  GdUnit4's CmdTool returns 100 on test failure — handle that explicitly.

## Reference

- https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- https://github.com/MikeSchulze/gdUnit4#command-line-tool
