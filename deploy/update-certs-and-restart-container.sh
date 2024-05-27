#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ENV_FILE="$SCRIPT_DIR/.env"

# 証明書と鍵のパス
CERT_PATH="/etc/letsencrypt/live/portfolio.cobaemon.com/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/portfolio.cobaemon.com/privkey.pem"

sudo sh -c 'echo "$(date): SSL certificates updated and containers restarted start." >> /var/log/cert_update.log'

sudo sh -c 'echo "$(date): Certificate and key encoding start..." >> /var/log/cert_update.log'
sudo /home/cobalt/deploy/Portfolio/deploy/encode-certs.sh

sudo sh -c 'echo "$(date): Reloading Nginx container with new certificates..." >> /var/log/cert_update.log'
sudo /home/cobalt/deploy/Portfolio/deploy/update-container-nginx-cert.sh

# ログの記録
echo -e "${GREEN}Logging the update...${RESET}"
sudo sh -c 'echo "$(date): SSL certificates updated and containers restarted." >> /var/log/cert_update.log'

echo -e "${GREEN}Script execution completed successfully.${RESET}"
