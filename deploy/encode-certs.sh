#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
MAGENTA="\e[35m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ENV_FILE="$SCRIPT_DIR/.env"

# 証明書と鍵のパス
CERT_PATH="/etc/letsencrypt/live/portfolio.cobaemon.com/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/portfolio.cobaemon.com/privkey.pem"

# .envファイルの存在確認
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}.env file not found at $ENV_FILE. Exiting.${RESET}"
    exit 1
fi

# Base64エンコード
echo -e "${MAGENTA}Encoding certificate and key...${RESET}"
if [ -f "$CERT_PATH" ]; then
    ENCODED_CERT=$(base64 -w 0 "$CERT_PATH")
else
    echo -e "${RED}Certificate file not found at $CERT_PATH. Exiting.${RESET}"
    exit 1
fi

if [ -f "$KEY_PATH" ]; then
    ENCODED_KEY=$(base64 -w 0 "$KEY_PATH")
else
    echo -e "${RED}Key file not found at $KEY_PATH. Exiting.${RESET}"
    exit 1
fi

# .envファイルの特定の行を更新
echo -e "${MAGENTA}Updating .env file with encoded certificate and key...${RESET}"
sudo sed -i "s|^SSL_CERTIFICATE=.*$|SSL_CERTIFICATE=$ENCODED_CERT|" "$ENV_FILE"
sudo sed -i "s|^SSL_CERTIFICATE_KEY=.*$|SSL_CERTIFICATE_KEY=$ENCODED_KEY|" "$ENV_FILE"

echo -e "${MAGENTA}Certificate and key encoding completed successfully.${RESET}"
