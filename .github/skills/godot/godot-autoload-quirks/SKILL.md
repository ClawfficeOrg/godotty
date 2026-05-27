---
name: godot-autoload-quirks
description: Surprising behaviors of Godot autoloads (singletons) and class_name
when_to_use: Touching anything in project/autoload/ or adding a new singleton
---

# Godot Autoload Quirks

## Quirk 1 — `class_name` collides with autoload name

If `project.godot` registers an autoload named `Foo`, you **cannot** also
write `class_name Foo` in the script. Godot will fail with:
"Class 'Foo' hides a global script class."

**Rule:** autoload scripts have **no** `class_name`. Reference the
singleton by its autoload name only.

## Quirk 2 — Autoloads are nodes, not classes

You access them as nodes: `TerminalManager.spawn_shell()`. They live under
`/root/<AutoloadName>`. They go through `_ready()` exactly once.

## Quirk 3 — Order matters

Autoloads in `project.godot` are loaded **top-to-bottom**. If `Foo` references
`Bar` in its `_ready()`, `Bar` must be listed first. Godotty's order is:

```
SignalBus       ← first; pure signal emitter, no deps
TerminalManager ← references SignalBus
```

Never reorder without reading every autoload's `_ready()`.

## Quirk 4 — Hot reload is unreliable on autoloads

After editing an autoload script, **restart the project**. The editor's
hot-reload often leaves stale state.

## Quirk 5 — `extends Node` is the only safe base for an autoload

Autoloads must extend `Node` or a subclass.

## Hard stop

Adding a **new** autoload is a Hard Stop in `AGENTS.md` §9. Pause and ask the
human.
