#!/usr/bin/env bash
# Clean the Godotty project cache without launching Godot

set -euo pipefail

cd "$(dirname "$0")/../project"

echo "Killing any running Godot instances..."
pkill -9 Godot 2>/dev/null || echo "No Godot instances running"

echo "Cleaning .godot cache..."
if [ -d .godot ]; then
    rm -rf .godot
    echo "Cache cleared: $(pwd)/.godot"
else
    echo "No cache to clear ($(pwd)/.godot doesn't exist)"
fi

echo ""
echo "Done! You can now open the project manually:"
echo "  cd $(pwd) && godot ."
echo ""
echo "Or with mock mode:"
echo "  cd $(pwd) && GODOTTY_FORCE_MOCK=1 godot ."
