#!/bin/bash

# define color codes
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'            # No Color

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
echo -e "${RED}Input text:${NC} ${BLUE}$INPUT_TEXT${NC}"

# 检测是否包含中文字符的函数
has_chinese() {
    local text="$1"
    # 使用 grep 检测中文字符，包括：
    # CJK统一汉字 (0x4E00-0x9FFF)
    # CJK扩展A区 (0x3400-0x4DBF)
    # CJK扩展B区 (0x20000-0x2A6DF)
    echo "$text" | grep -q '[一-龥]'
}

# auto-detect source and target languages
if has_chinese "$INPUT_TEXT"; then
    SOURCE_LANG="ZH"
    TARGET_LANG="EN"
else
    SOURCE_LANG="EN"
    TARGET_LANG="ZH"
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
echo -e "${GREEN}Primary:${NC} $MAIN_TRANSLATION"

# get all possible translations
# echo -e "\n${YELLOW}Alternatives:${NC}"
echo -e "\n${YELLOW}Alternatives:${NC}"
echo "$RESPONSE" | jq -r '.alternatives[]' | while read -r line; do
    # echo -e "${YELLOW}- $line${NC}"

    echo -e "- $line"
done
