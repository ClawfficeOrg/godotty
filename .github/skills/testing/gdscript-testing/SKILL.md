---
name: gdscript-testing
description: Write a GdUnit4 test, mock-mode patterns, fixtures
when_to_use: Whenever you add behavior. Always.
---

# GDScript Testing — GdUnit4

## File layout

```
tests/
├── unit/                      ← isolated, no scene tree dependency
│   ├── terminal_manager_pwd_test.gd
│   └── signal_bus_connectivity_test.gd
└── integration/
    ├── mock/                  ← scene tree, mock-mode only
    └── real/                  ← requires godotty-node addon (CI nightly)
```

Test file naming: `<thing-under-test>_<scenario>_test.gd`.

## Skeleton

```gdscript
class_name TerminalManagerPwdTest
extends GdUnitTestSuite

func before_test() -> void:
    TerminalManager._mock_current_dir = "/home/user"

func test_pwd_returns_home_user_by_default() -> void:
    var output := TerminalManager._mock_process_command("pwd", "")
    assert_str(output).is_equal("/home/user")
```

## Patterns

### Asserting a signal fired

```gdscript
func test_output_ready_emits_after_command() -> void:
    var monitor := monitor_signals(SignalBus)
    TerminalManager.write_input("echo hi")
    await await_signal_on(SignalBus, "output_ready", [], 200)
    assert_signal(monitor).is_emitted("output_ready")
```

### Async / awaiting

GdUnit4 supports `await` inside `func test_*` directly. Use `await_idle_frame()`
to let the engine tick.

### Fixture for a TerminalView in unit tests

```gdscript
var _view: TerminalView

func before_test() -> void:
    _view = preload("res://scenes/terminal.tscn").instantiate()
    add_child(_view)
    await _view._ready

func after_test() -> void:
    _view.queue_free()
```

## Running

```sh
scripts/run_tests.sh                    # all tests
scripts/run_tests.sh tests/unit         # just unit
scripts/run_tests.sh tests/unit/foo.gd  # one file
```

## Hard rules

- **Every** new behavior gets a test.
- **Every** bug fix begins with a failing regression test.
- A test that flakes is a test that fails. Find the race; usually it's a
  missing `await get_tree().process_frame`.
