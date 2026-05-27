#!/usr/bin/env bash
# Clean and restart the Godotty project

set -euo pipefail

cd "$(dirname "$0")/../project"

echo "Killing any running Godot instances..."
pkill -9 Godot || true

echo "Cleaning .godot cache..."
rm -rf .godot

echo "Starting Godot..."
godot .
