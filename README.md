# Godotty

**Godotty** is a demonstration app for the GodottyNode GDExtension, which provides a TerminalNode2D for virtual terminal emulation.

## Getting Started

1. Clone the `godotty-node` repository and build the GDExtension:
```bash
git clone https://github.com/ClawfficeOrg/godotty-node.git
cd godotty-node
cargo build --release
```

2. Add the extension to your Godot project:
- Copy `godotty-node/target/release/libgodotty_node.so` (Linux) or equivalent for your platform.
- Place it in your project's `native/` directory.

3. Include the GDExtension in `project.godot`:
```ini
[ext_resource path="res://native/libgodotty_node.so" type="GDNativeLibrary" id=1]
```
