#!/bin/bash

# 色の定義
LIGHT_CYAN="\e[96m"
LIGHT_RED="\e[91m"
RESET="\e[0m"

# テスト用のURLを設定
URL="https://portfolio.cobaemon.com/portfolio/top"

# 外部サービスを利用してリクエストを送信し、ヘッダーを取得
response=$(curl -s -I https://httpbin.org/get?url=$URL)

# レスポンスヘッダーを表示
echo -e "${LIGHT_CYAN}Response Headers:${RESET}"
echo "$response"

# Referrer-Policyヘッダーを抽出
referrer_policy=$(echo "$response" | grep -i "Referrer-Policy")

# Referrer-Policyヘッダーを表示
if [ -n "$referrer_policy" ]; then
    echo -e "${LIGHT_CYAN}Referrer-Policy:${RESET} $referrer_policy"
else
    echo -e "${LIGHT_RED}Referrer-Policy header not found.${RESET}"
fi
