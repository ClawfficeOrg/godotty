#!/usr/bin/env bash
# Install godotty-node GDExtension from source at a pinned ref.
#
# Clones ClawfficeOrg/godotty-node at GODOTTY_NODE_REF, builds with
# `cargo build --release`, and installs the resulting library into
# project/addons/godotty-node/bin/<platform>/.
#
# Env:
#   GODOTTY_NODE_REF   Git ref (SHA, tag, branch) to check out.
#                      Default: pinned SHA set in nightly-real.yml.
#   GODOTTY_NODE_REPO  Override the clone URL (useful for forks / local mirrors).
#
# Exit codes:
#   0  success — library installed
#   1  build or install failure
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Pinned SHA: bumped by a one-line change here or in nightly-real.yml env block.
GODOTTY_NODE_REF="${GODOTTY_NODE_REF:-c9e3630600392dd9fb65497dc582b6a6bc2611c3}"
GODOTTY_NODE_REPO="${GODOTTY_NODE_REPO:-https://github.com/ClawfficeOrg/godotty-node.git}"

ADDON_BIN="project/addons/godotty-node/bin"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "install_godotty_node: cloning $GODOTTY_NODE_REPO at $GODOTTY_NODE_REF ..."
git clone --no-tags --depth=1 "$GODOTTY_NODE_REPO" "$tmp/godotty-node"
git -C "$tmp/godotty-node" fetch --depth=1 origin "$GODOTTY_NODE_REF"
git -C "$tmp/godotty-node" checkout FETCH_HEAD

echo "install_godotty_node: building (cargo build --release) ..."
cargo build --release --manifest-path "$tmp/godotty-node/rust/Cargo.toml"

case "$(uname -s)" in
	Darwin)
		LIB="$tmp/godotty-node/rust/target/release/libgodotty_node.dylib"
		DEST="$ADDON_BIN/macos"
		mkdir -p "$DEST"
		cp "$LIB" "$DEST/libgodotty_node.dylib"
		echo "install_godotty_node: installed macos/libgodotty_node.dylib"
		;;
	Linux)
		LIB="$tmp/godotty-node/rust/target/release/libgodotty_node.so"
		DEST="$ADDON_BIN/linux"
		mkdir -p "$DEST"
		cp "$LIB" "$DEST/libgodotty_node.so"
		echo "install_godotty_node: installed linux/libgodotty_node.so"
		;;
	*)
		echo "install_godotty_node: unsupported platform $(uname -s)" >&2
		exit 1
		;;
esac

echo "install_godotty_node: done (ref $GODOTTY_NODE_REF)"
