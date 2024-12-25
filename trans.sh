#!/bin/bash

# define color codes
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'        # No Color

# You need to replace this with a real access token
ACCESS_TOKEN="your_access_token"

# translation API URL
API_URL="http://localhost:1188/translate"

# 检查是否提供了参数
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Usage: $0 <text_to_translate>${NC}"
    exit 1
fi

INPUT_TEXT="$1"
# echo -e "${BLUE}Input text: $INPUT_TEXT${NC}"
echo -e "Input text: ${BLUE}$INPUT_TEXT${NC}"

# auto-detect source and target languages
if [[ "$INPUT_TEXT" =~ [a-zA-Z] ]]; then
    SOURCE_LANG="EN"
    TARGET_LANG="ZH"
else
    SOURCE_LANG="ZH"
    TARGET_LANG="EN"
fi

# call the API to translate
RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "{
    \"text\": \"$INPUT_TEXT\",
    \"source_lang\": \"$SOURCE_LANG\",
    \"target_lang\": \"$TARGET_LANG\"
}")

# get the translation results
echo -e "\n${YELLOW}Translated results:${NC}"
# echo -e "${YELLOW}-------------------${NC}"
echo -e "-------------------"
# get the main translation result
MAIN_TRANSLATION=$(echo "$RESPONSE" | jq -r .data)
# echo -e "${YELLOW}Primary: $MAIN_TRANSLATION${NC}"
echo -e "Primary: $MAIN_TRANSLATION"

# get all possible translations
# echo -e "\n${YELLOW}Alternatives:${NC}"
echo -e "\n${YELLOW}Alternatives:${NC}"
echo "$RESPONSE" | jq -r '.alternatives[]' | while read -r line; do
    # echo -e "${YELLOW}- $line${NC}"
    echo -e "- $line"
done
