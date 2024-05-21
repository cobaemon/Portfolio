#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
LIGHT_CYAN="\e[96m"
LIGHT_RED="\e[91m"
RESET="\e[0m"

# テスト用のログファイルを設定
LOG_FILE="referrer_policy_test.log"

# ログファイルをクリア
> $LOG_FILE

# テストページのURLを設定
TEST_URL="http://portfolio.cobaemon.com/portfolio/top"

# Nginxの設定ファイルをチェック
echo -e "${LIGHT_CYAN}Checking Nginx configuration for Referrer-Policy...${RESET}"
if grep -q 'add_header Referrer-Policy "strict-origin-when-cross-origin";' /etc/nginx/conf.d/portfolio.conf; then
    echo -e "${LIGHT_CYAN}Referrer-Policy is correctly set in Nginx configuration.${RESET}" | tee -a $LOG_FILE
else
    echo -e "${LIGHT_RED}Referrer-Policy is not correctly set in Nginx configuration.${RESET}" | tee -a $LOG_FILE
    exit 1
fi

# テストリクエストの送信とリファラの確認
echo -e "${LIGHT_CYAN}Sending test request to check Referrer-Policy...${RESET}"

# 同一オリジンからのリクエスト
SAME_ORIGIN_REFERRER=$(curl -s -o /dev/null -w '%{redirect_url}' -e $TEST_URL $TEST_URL)
if [ -z "$SAME_ORIGIN_REFERRER" ]; then
    echo -e "${LIGHT_CYAN}Same-origin referrer policy is working correctly.${RESET}" | tee -a $LOG_FILE
else
    echo -e "${LIGHT_RED}Same-origin referrer policy is not working correctly.${RESET}" | tee -a $LOG_FILE
    exit 1
fi

# クロスオリジンからのリクエスト
CROSS_ORIGIN_REFERRER=$(curl -s -o /dev/null -w '%{redirect_url}' -e "http://another-domain.com" $TEST_URL)
if [ -n "$CROSS_ORIGIN_REFERRER" ] && [[ $CROSS_ORIGIN_REFERRER == "http://portfolio.cobaemon.com" ]]; then
    echo -e "${LIGHT_CYAN}Cross-origin referrer policy is working correctly.${RESET}" | tee -a $LOG_FILE
else
    echo -e "${LIGHT_RED}Cross-origin referrer policy is not working correctly.${RESET}" | tee -a $LOG_FILE
    exit 1
fi

echo -e "${LIGHT_CYAN}Referrer-Policy verification completed successfully.${RESET}" | tee -a $LOG_FILE
