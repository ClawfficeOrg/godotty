#!/usr/bin/env bash
# Clean and open the Godotty project in the editor
# (The editor must scan scripts before the project can run)

set -euo pipefail

cd "$(dirname "$0")/../project"

echo "Killing any running Godot instances..."
pkill -9 Godot || true

echo "Cleaning .godot cache..."
rm -rf .godot

echo "Opening Godot Editor..."
echo "(Wait for script scanning to complete, then press F5 to run)"
godot --editor project.godot
