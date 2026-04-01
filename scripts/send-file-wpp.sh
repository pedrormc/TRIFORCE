#!/bin/bash
# TRIFORCE — Send file directly via WhatsApp (base64, Evolution API)
# Usage: ~/send-file-wpp.sh <file> <phone_number>
#
# Requires ~/.env.triforce with EVOLUTION_URL, EVOLUTION_API_KEY, EVOLUTION_INSTANCE

# Load config
if [ -f "$HOME/.env.triforce" ]; then
    source "$HOME/.env.triforce"
fi

FILE="$1"
PHONE="$2"

if [ -z "$FILE" ] || [ -z "$PHONE" ]; then
    echo "Usage: send-file-wpp.sh <file> <phone_number>"
    echo "Example: send-file-wpp.sh report.pdf 5561999999999"
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
MIMETYPE=$(file --mime-type -b "$FILE")
BASE64=$(base64 -w 0 "$FILE")

echo "Sending $FILENAME ($MIMETYPE) to $PHONE via WhatsApp..."

curl -s -X POST "$EVOLUTION_URL/message/sendMedia/$EVOLUTION_INSTANCE" \
    -H "Content-Type: application/json" \
    -H "apikey: $EVOLUTION_API_KEY" \
    -d "{
        \"number\": \"$PHONE\",
        \"mediatype\": \"document\",
        \"mimetype\": \"$MIMETYPE\",
        \"caption\": \"$FILENAME\",
        \"media\": \"data:$MIMETYPE;base64,$BASE64\",
        \"fileName\": \"$FILENAME\"
    }"

echo ""
echo "Done!"
