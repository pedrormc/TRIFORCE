#!/bin/bash
# TRIFORCE — Upload file to Google Drive + send link via WhatsApp (Evolution API)
# Usage: ~/send-doc.sh <file> <phone_number>
#
# Requires:
# - rclone configured with "gdrive" remote (scope 1 = full access)
# - ~/.env.triforce with EVOLUTION_URL, EVOLUTION_API_KEY, EVOLUTION_INSTANCE

# Load config
if [ -f "$HOME/.env.triforce" ]; then
    source "$HOME/.env.triforce"
fi

FILE="$1"
PHONE="$2"

if [ -z "$FILE" ] || [ -z "$PHONE" ]; then
    echo "Usage: send-doc.sh <file> <phone_number>"
    echo "Example: send-doc.sh report.pdf 5561999999999"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

if [ -z "$EVOLUTION_URL" ] || [ -z "$EVOLUTION_API_KEY" ] || [ -z "$EVOLUTION_INSTANCE" ]; then
    echo "Missing Evolution API config. Set in ~/.env.triforce:"
    echo "  EVOLUTION_URL=https://..."
    echo "  EVOLUTION_API_KEY=..."
    echo "  EVOLUTION_INSTANCE=..."
    exit 1
fi

FILENAME=$(basename "$FILE")

echo "Uploading $FILENAME to Google Drive..."
LINK=$(rclone link "gdrive:TRIFORCE/$FILENAME" --expire 7d 2>/dev/null)

if [ -z "$LINK" ]; then
    # Upload first, then get link
    rclone copy "$FILE" "gdrive:TRIFORCE/" --progress
    LINK=$(rclone link "gdrive:TRIFORCE/$FILENAME" --expire 7d 2>/dev/null)
fi

if [ -z "$LINK" ]; then
    echo "Failed to get Drive link"
    exit 1
fi

echo "Sending via WhatsApp to $PHONE..."
curl -s -X POST "$EVOLUTION_URL/message/sendText/$EVOLUTION_INSTANCE" \
    -H "Content-Type: application/json" \
    -H "apikey: $EVOLUTION_API_KEY" \
    -d "{
        \"number\": \"$PHONE\",
        \"text\": \"Documento: $FILENAME\n\nLink: $LINK\"
    }"

echo ""
echo "Done! Link: $LINK"
