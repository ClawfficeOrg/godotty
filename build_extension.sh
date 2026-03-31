#!/usr/bin/env bash
# build_extension.sh — Build godotty-node GDExtension and copy to project
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOTTY_NODE_DIR="${GODOTTY_NODE_DIR:-$(dirname "$SCRIPT_DIR")/godotty-node}"
OUT_DIR="$SCRIPT_DIR/project/addons/godotty-node/bin"

if [ ! -d "$GODOTTY_NODE_DIR/rust" ]; then
  echo "ERROR: godotty-node not found at $GODOTTY_NODE_DIR"
  echo "Clone it: git clone https://github.com/ClawfficeOrg/godotty-node.git"
  exit 1
fi

echo "Building godotty-node..."
cd "$GODOTTY_NODE_DIR/rust"
cargo build --release

# Detect platform and copy
if [ "$(uname)" = "Darwin" ]; then
  mkdir -p "$OUT_DIR/macos"
  cp target/release/libgodotty_node.dylib "$OUT_DIR/macos/"
  echo "Copied: macos/libgodotty_node.dylib"
else
  mkdir -p "$OUT_DIR/linux"
  cp target/release/libgodotty_node.so "$OUT_DIR/linux/"
  echo "Copied: linux/libgodotty_node.so"
fi

echo "Done! Enable the godotty-node plugin in Project Settings → Plugins."
