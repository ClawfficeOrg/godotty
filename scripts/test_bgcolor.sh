#!/usr/bin/env bash
# Test background color rendering manually in the terminal

set -euo pipefail

echo "Testing ANSI background colors..."
echo ""

ESC=$'\e'

# Standard background colors (40-47)
echo "${ESC}[40mBlack BG${ESC}[0m"
echo "${ESC}[41mRed BG${ESC}[0m"
echo "${ESC}[42mGreen BG${ESC}[0m"
echo "${ESC}[43mYellow BG${ESC}[0m"
echo "${ESC}[44mBlue BG${ESC}[0m"
echo "${ESC}[45mMagenta BG${ESC}[0m"
echo "${ESC}[46mCyan BG${ESC}[0m"
echo "${ESC}[47mWhite BG${ESC}[0m"

echo ""

# Bright background colors (100-107)
echo "${ESC}[100mBright Black BG${ESC}[0m"
echo "${ESC}[101mBright Red BG${ESC}[0m"
echo "${ESC}[102mBright Green BG${ESC}[0m"
echo "${ESC}[103mBright Yellow BG${ESC}[0m"
echo "${ESC}[104mBright Bright Blue BG${ESC}[0m"
echo "${ESC}[105mBright Magenta BG${ESC}[0m"
echo "${ESC}[106mBright Cyan BG${ESC}[0m"
echo "${ESC}[107mBright White BG${ESC}[0m"

echo ""

# Combined foreground + background
echo "${ESC}[33;44mYellow text on Blue background${ESC}[0m"
echo "${ESC}[31;42mRed text on Green background${ESC}[0m"
echo "${ESC}[97;41mWhite text on Red background${ESC}[0m"

echo ""

# 256-color background
echo "${ESC}[48;5;196mXterm 196 (bright red) background${ESC}[0m"
echo "${ESC}[48;5;21mXterm 21 (blue) background${ESC}[0m"

echo ""

# RGB background
echo "${ESC}[48;2;255;128;0mRGB orange background${ESC}[0m"
echo "${ESC}[48;2;0;200;100mRGB teal background${ESC}[0m"

echo ""
echo "All tests complete!"
