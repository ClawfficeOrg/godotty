---
name: godot-signals
description: Signal patterns and the SignalBus contract
when_to_use: Adding, modifying, or connecting signals
---

# Godot Signals — godotty contract

## The SignalBus

`SignalBus` (autoload) is the **only** legal channel between
`TerminalView` and `TerminalManager`. Direct method calls across that
boundary are forbidden.

Current signals (see `project/autoload/signal_bus.gd`):

```gdscript
signal command_submitted(command: String)
signal output_ready(text: String)
signal terminal_cleared()
signal addon_status_changed(available: bool)
signal shell_status_changed(running: bool)
```

## Adding a signal

1. Declare in `signal_bus.gd` with **typed parameters**.
2. Document with a `##` comment above the declaration.
3. Add to the SignalBus section of `README.md`.
4. Update `tests/unit/signal_bus_connectivity_test.gd` to assert it exists.
5. CHANGELOG entry under `[Unreleased] / Added`.

## Connecting

Always use `Callable` form (Godot 4):

```gdscript
SignalBus.output_ready.connect(_on_output_ready)
```

**Don't** use the Godot 3 string form.

## Disconnecting

```gdscript
func _exit_tree() -> void:
    if SignalBus.output_ready.is_connected(_on_output_ready):
        SignalBus.output_ready.disconnect(_on_output_ready)
```

## One-shots

```gdscript
SignalBus.shell_status_changed.connect(_on_first_shell, CONNECT_ONE_SHOT)
```

## Don't

- ❌ Emit signals from `_ready()` of an autoload (other autoloads may not
  have connected yet). Use `call_deferred` if you must.
- ❌ Add a signal to `TerminalManager` directly — put it on `SignalBus`.
- ❌ Pass nodes through signals across the manager↔view boundary.
  Pass plain data only.
