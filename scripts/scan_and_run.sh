#!/usr/bin/env bash
# Scan scripts in editor then run the project from command line

set -euo pipefail

cd "$(dirname "$0")/../project"

echo "Killing any running Godot instances..."
pkill -9 Godot 2>/dev/null || true

echo "Cleaning .godot cache..."
rm -rf .godot

echo "Opening editor to scan scripts (will auto-close)..."
# Open editor, wait for it to fully load, then close it
godot --editor --headless --quit project.godot 2>&1 | grep -v "Unicode parsing error" &
EDITOR_PID=$!

# Wait for the editor process to finish
wait $EDITOR_PID 2>/dev/null || true

# Give it a moment to write the cache
sleep 2

echo "Scripts scanned! Now running the project..."
godot .
