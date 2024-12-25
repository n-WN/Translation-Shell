#!/bin/bash

# --------------------------------------------------
# Script Name: translation.sh
# Description:
#   This script sends a text string to a translation
#   API, automatically determines the source and
#   target languages, and prints the results.
# --------------------------------------------------

# --------------------------------------------------
# Color Codes
# --------------------------------------------------
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# --------------------------------------------------
# Configuration
# --------------------------------------------------
ACCESS_TOKEN="your_access_token"  # Replace with valid access token
API_URL="http://localhost:1188/translate"  # Base URL for the translation API

# --------------------------------------------------
# Functions
# --------------------------------------------------

# usage:
#   Displays the correct usage of this script.
usage() {
    echo -e "${YELLOW}Usage: $0 <text_to_translate>${NC}"
}

# has_chinese:
#   Checks if the specified string contains any Chinese
#   characters (in the U+4E00–U+9FFF range).
has_chinese() {
    local text="$1"
    python3 -c "
import sys
input_text = sys.argv[1]
for char in input_text:
    if '\u4e00' <= char <= '\u9fff':
        sys.exit(0)
sys.exit(1)
" "$text"
}

# --------------------------------------------------
# Main Script
# --------------------------------------------------

# Ensure at least one argument is provided.
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

# Capture the input text.
INPUT_TEXT="$1"

# Print the input text in color-coded format for clarity.
echo -e "${RED}Input text:${NC} ${BLUE}$INPUT_TEXT${NC}"

# --------------------------------------------------
# Automatic Language Detection
# --------------------------------------------------
# 1. If the input begins with "tran", remove it and assume EN -> ZH.
# 2. Otherwise, detect Chinese characters. If found, ZH -> EN; else EN -> ZH.
if [[ "$INPUT_TEXT" == tran* ]]; then
    # Remove the "tran" prefix and any leading/trailing whitespace.
    INPUT_TEXT="${INPUT_TEXT#tran}"
    INPUT_TEXT="${INPUT_TEXT#"${INPUT_TEXT%%[![:space:]]*}"}"
    INPUT_TEXT="${INPUT_TEXT%"${INPUT_TEXT##*[![:space:]]}"}"
    SOURCE_LANG="EN"
    TARGET_LANG="ZH"
else
    if has_chinese "$INPUT_TEXT"; then
        SOURCE_LANG="ZH"
        TARGET_LANG="EN"
    else
        SOURCE_LANG="EN"
        TARGET_LANG="ZH"
    fi
fi

# --------------------------------------------------
# API Request
# --------------------------------------------------
# Send a POST request with JSON data to the translation API.
RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "{
    \"text\": \"$INPUT_TEXT\",
    \"source_lang\": \"$SOURCE_LANG\",
    \"target_lang\": \"$TARGET_LANG\"
}")

# Check if the API response is valid JSON.
if ! echo "$RESPONSE" | jq -e . >/dev/null 2>&1; then
    echo -e "${RED}Error: Invalid API response received.${NC}" >&2
    exit 1
fi

# Extract the status code from the JSON response.
STATUS_CODE=$(echo "$RESPONSE" | jq -r '.code')

# If the status code is not 200, handle specific error codes or display a general error.
if [ "$STATUS_CODE" != "200" ]; then
    echo -e "${RED}Error: Translation failed.${NC}" >&2
    echo -e "${RED}Status code: $STATUS_CODE${NC}" >&2
    
    case $STATUS_CODE in
        429)
            echo -e "${RED}Too many requests. Please try again later.${NC}" >&2
            ;;
        401)
            echo -e "${RED}Unauthorized. Check your access token.${NC}" >&2
            ;;
        *)
            echo -e "${RED}Unknown error occurred.${NC}" >&2
            ;;
    esac
    echo -e "${RED}API Response:${NC}" >&2
    echo "$RESPONSE" | jq '.' >&2
    exit 1
fi

# --------------------------------------------------
# Display Translation Results
# --------------------------------------------------
# Extract the primary translation.
MAIN_TRANSLATION=$(echo "$RESPONSE" | jq -r .data)

echo -e "\n${YELLOW}Translated results:${NC}"
echo -e "-------------------"
echo -e "${GREEN}Primary:${NC} $MAIN_TRANSLATION"

# Extract and display alternative translations.
echo -e "\n${YELLOW}Alternatives:${NC}"
echo "$RESPONSE" | jq -r '.alternatives[]' | while read -r alt; do
    echo -e "- $alt"
done