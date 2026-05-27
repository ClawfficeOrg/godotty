# Development Scripts

Utility scripts for Godotty development and testing.

## Cache Management

### `clean_cache.sh`
Cleans the `.godot` cache and kills running Godot instances without launching.

**Usage:**
```bash
./scripts/clean_cache.sh
```

**When to use:**
- Parse errors mentioning "Could not find type"
- After modifying `class_name` declarations
- When you want to manually control when Godot starts

### `clean_restart.sh`
Cleans cache, kills Godot, and automatically launches the project.

**Usage:**
```bash
./scripts/clean_restart.sh
```

**When to use:**
- Quick development restart
- When you want automatic launch after cleanup

## Testing

### `test_bgcolor.sh`
Manual test for ANSI background color rendering.

**Usage:**
Run from inside the Godotty terminal:
```bash
./scripts/test_bgcolor.sh
```

Displays various background colors (40-47, 100-107, 256-color, RGB) to visually verify rendering.

## Tips

- Use `clean_cache.sh` if `clean_restart.sh` has issues
- Run cache cleanup after `git pull` if you see parse errors
- Use `GODOTTY_FORCE_MOCK=1` environment variable to test without the GDExtension
