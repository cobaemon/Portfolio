#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
CYAN="\e[36m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# 環境変数から証明書と鍵をデコードして配置
echo -e "${CYAN}Decoding and placing SSL certificates...${RESET}"
if [ -z "$SSL_CERTIFICATE" ] || [ -z "$SSL_CERTIFICATE_KEY" ]; then
    echo -e "${RED}Environment variables SSL_CERTIFICATE or SSL_CERTIFICATE_KEY are not set. Exiting.${RESET}"
    exit 1
fi

# 証明書のデコードと配置
echo "$SSL_CERTIFICATE" | base64 -d > /etc/ssl/certs/fullchain.pem
echo "$SSL_CERTIFICATE_KEY" | base64 -d > /etc/ssl/private/privkey.pem

# ファイルのパーミッションを設定
sudo chmod 644 /etc/ssl/certs/fullchain.pem
sudo chmod 600 /etc/ssl/private/privkey.pem

# Nginxをデーモンとして起動
echo -e "${CYAN}Starting Nginx...${RESET}"
nginx -g 'daemon off;'

echo -e "${CYAN}Nginx has been started successfully.${RESET}"
