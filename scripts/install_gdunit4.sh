#!/usr/bin/env bash
# Install GdUnit4 into project/addons/gdUnit4 at a pinned version.
# Spec: .ralph/specs/0002-gdunit4-test-harness.md
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# v6.1.x targets Godot 4.5+ (we're on 4.6). Repo moved to godot-gdunit-labs/gdUnit4.
# See: https://github.com/godot-gdunit-labs/gdUnit4/releases
VERSION="${GDUNIT4_VERSION:-v6.1.3}"
DEST="project/addons/gdUnit4"
URL="https://github.com/godot-gdunit-labs/gdUnit4/archive/refs/tags/${VERSION}.tar.gz"

if [[ -d "$DEST" ]] && [[ "${1:-}" != "--force" ]]; then
	echo "install_gdunit4: $DEST already exists. Pass --force to reinstall."
	exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "install_gdunit4: fetching $VERSION ..."
curl -fsSL "$URL" | tar xz -C "$tmp"

extracted="$(find "$tmp" -maxdepth 1 -type d -name 'gdUnit4-*' | head -n1)"
if [[ -z "$extracted" ]]; then
	echo "install_gdunit4: extraction failed" >&2
	exit 1
fi

mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
mv "$extracted/addons/gdUnit4" "$DEST"

echo "install_gdunit4: installed $VERSION to $DEST"
