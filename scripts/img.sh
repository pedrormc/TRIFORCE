#!/data/data/com.termux/files/usr/bin/bash
# TRIFORCE — Send most recent screenshot to Claude Code (Mobile)
# Usage: ~/img.sh

SCREENSHOT_DIR="$HOME/storage/dcim/Screenshots"

if [ ! -d "$SCREENSHOT_DIR" ]; then
    echo "Screenshots dir not found: $SCREENSHOT_DIR"
    echo "Try: termux-setup-storage"
    exit 1
fi

LATEST=$(find "$SCREENSHOT_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)

if [ -z "$LATEST" ]; then
    echo "No screenshots found in $SCREENSHOT_DIR"
    exit 1
fi

echo "Sending: $LATEST"
cc --image "$LATEST"
