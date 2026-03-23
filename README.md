# Godotty

**Godotty** is a demonstration app for the [godotty-node](https://github.com/ClawfficeOrg/godotty-node) GDExtension, which provides terminal emulation capabilities for Godot 4.6 projects.

![Terminal Demo](screenshots/terminal-demo.png)

## Features

- 🖥️ **Terminal Emulation** - Full terminal UI with ANSI color support
- 📦 **Mock Mode** - Works without the GDExtension for development
- 🎨 **Pixel Art Style** - Retro terminal aesthetic
- ⌨️ **Command History** - Navigate with arrow keys
- 🔌 **Hot-Swap Backend** - Seamlessly switch between mock and real terminal

## Quick Start

### Running in Mock Mode

The app works out of the box in mock mode without any additional setup:

```bash
cd project
godot4 .
```

Or open `project/project.godot` in the Godot Editor.

### Building with godotty-node

To use the real terminal emulation:

1. **Build the GDExtension**:
   ```bash
   git clone https://github.com/ClawfficeOrg/godotty-node.git
   cd godotty-node
   cargo build --release
   ```

2. **Install the extension**:
   ```bash
   mkdir -p ../godotty/project/addons/godotty-node
   cp target/release/libgodotty_node.so ../godotty/project/addons/godotty-node/
   cp godotty_node.gdextension ../godotty/project/addons/godotty-node/
   ```

3. **Run the project**:
   ```bash
   cd ../godotty/project
   godot4 .
   ```

## Project Structure

```
project/
├── project.godot          # Project configuration
├── autoload/              # Global singletons
│   ├── signal_bus.gd      # Event bus for decoupled communication
│   └── terminal_manager.gd # Terminal backend (real/mock)
├── scenes/
│   ├── main.tscn          # Main application scene
│   └── terminal.tscn      # Terminal UI component
├── scripts/
│   ├── main.gd            # Main scene controller
│   └── terminal_view.gd   # Terminal display logic
├── resources/
│   └── themes/
│       └── terminal_theme.tres # UI theming
└── addons/                # GDExtensions (gitignored)
    └── godotty-node/      # Real terminal extension
```

## Architecture

### Signal-Based Design

Godotty uses a signal-based architecture for loose coupling:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   TerminalView  │────▶│   SignalBus     │────▶│ TerminalManager │
│   (UI Layer)    │     │   (Event Bus)   │     │   (Backend)     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**Key Signals:**
- `command_submitted(command: String)` - User entered a command
- `output_ready(text: String)` - Terminal output ready to display
- `terminal_cleared()` - Terminal was cleared
- `addon_status_changed(available: bool)` - GDExtension status changed
- `shell_status_changed(running: bool)` - Shell started/stopped

### Mock Terminal

When godotty-node is not available, the app runs in mock mode with a simulated terminal supporting:

| Command | Description |
|---------|-------------|
| `help` | Show available commands |
| `clear` | Clear the terminal |
| `echo <text>` | Echo text back |
| `pwd` | Print working directory |
| `cd <dir>` | Change directory |
| `ls` | List files |
| `cat <file>` | Show file contents |
| `date` | Show current date/time |
| `whoami` | Show current user |
| `exit` | Exit the shell |

### Real Terminal (godotty-node)

When the GDExtension is available, commands are executed in a real PTY shell. The `TerminalManager` automatically detects availability and switches backends.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Enter` | Submit command |
| `↑` / `↓` | Navigate command history |
| `Ctrl+C` | Interrupt current input |
| `Tab` | (TODO) Auto-complete |

## Development

### Requirements

- Godot 4.6+
- Rust 1.70+ (for godotty-node)

### Running Tests

```bash
# TODO: Add GdUnit4 tests
```

### Adding Commands (Mock Mode)

Edit `autoload/terminal_manager.gd` and add to `_mock_process_command()`:

```gdscript
"mycommand":
    return "My command output"
```

## Screenshots

| Mock Mode | Real Terminal |
|-----------|---------------|
| ![Mock Mode](screenshots/mock-mode.png) | ![Real Terminal](screenshots/real-terminal.png) |

## Related Projects

- [godotty-node](https://github.com/ClawfficeOrg/godotty-node) - The GDExtension this app demonstrates
- [Clawffice-Space](https://github.com/ClawfficeOrg/Clawffice-Space) - The main Clawffice project

## License

MIT License - See [LICENSE](LICENSE) for details.

---

*Part of the Clawffice Collective* 🦞🤖
