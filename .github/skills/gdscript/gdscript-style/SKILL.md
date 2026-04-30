---
name: gdscript-style
description: House style for .gd files in godotty (naming, types, layout, idioms)
when_to_use: Before writing or modifying any .gd file in project/ or tests/
---

# GDScript Style — godotty

## Order in a file

1. Top-of-file `##` doc comment block — what the script does.
2. `class_name` (only if the script is referenced externally **and** is
   not registered as an autoload — see `godot-autoload-quirks`).
3. `extends`.
4. `const`s (UPPER_SNAKE).
5. `enum`s.
6. `signal`s.
7. `@export` variables.
8. Other instance vars (private prefixed `_`).
9. `@onready` vars.
10. Built-in callbacks (`_ready`, `_process`, `_input`, …) in lifecycle order.
11. Public methods.
12. Private methods (prefixed `_`).
13. Inner classes (rare).

## Naming

- `snake_case` for vars, functions, files.
- `PascalCase` for class names, enums, autoload singleton names.
- `UPPER_SNAKE` for `const`.
- Private members: leading `_`.

## Types — always

```gdscript
var name: String = ""
func add(a: int, b: int) -> int:
    return a + b
```

Untyped `var x = ...` is **not** allowed in this codebase. Exceptions:
- Throwaway lambdas where types add noise and the lifetime is one expression.
- `match` arm captures (Godot doesn't allow type hints there).

## Doc comments

`##` (double-hash) only. They become Godot Editor help.

## Tabs, not spaces

Godot's editor and `gdformat` both use tabs. Don't fight it.

## Strings

- Use `"..."` (double quotes) consistently.
- Use `%`-formatting for templates: `"%s = %d" % [name, n]`.
- Multi-line: triple-quoted `"""..."""`.

## Comparisons

- `is_empty()` not `== ""` for strings/arrays.
- `is_zero_approx()` not `== 0.0` for floats.
- `is_instance_valid(node)` before touching a node that might be freed.

## Don'ts

- ❌ `class_name` on an autoload script.
- ❌ Untyped vars/params.
- ❌ `print()` for runtime logs in shipping code — prefer `push_warning` /
  `push_error`.
