#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
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

# 証明書と鍵のエンコード
if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    echo -e "${YELLOW}Encoding certificate and key...${RESET}"
    ENCODED_CERT=$(sudo base64 -w 0 "$CERT_PATH")
    ENCODED_KEY=$(sudo base64 -w 0 "$KEY_PATH")
else
    echo -e "${RED}Certificate or key file not found. Exiting.${RESET}"
    exit 1
fi

# .envファイルの更新
echo -e "${YELLOW}Updating .env file with encoded certificate and key...${RESET}"
sed -i "s|^SSL_CERTIFICATE=.*$|SSL_CERTIFICATE=$ENCODED_CERT|" "$ENV_FILE"
sed -i "s|^SSL_CERTIFICATE_KEY=.*$|SSL_CERTIFICATE_KEY=$ENCODED_KEY|" "$ENV_FILE"

# Dockerコンテナの再起動
echo -e "${YELLOW}Restarting Docker containers...${RESET}"
cd /home/cobalt/deploy/Portfolio
docker compose -f deploy/docker-compose.yaml down
docker compose -f deploy/docker-compose.yaml build --no-cache
docker compose -f deploy/docker-compose.yaml up -d

# ログの記録
echo -e "${YELLOW}Logging the update...${RESET}"
sudo sh -c 'echo "$(date): SSL certificates updated and containers restarted." >> /var/log/cert_update.log'

echo -e "${YELLOW}Script execution completed successfully.${RESET}"
