#!/bin/bash

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ENV_FILE="$SCRIPT_DIR/.env"

# 証明書と鍵のパス
CERT_PATH="/etc/letsencrypt/live/portfolio.cobaemon.com/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/portfolio.cobaemon.com/privkey.pem"

# Base64エンコード
ENCODED_CERT=$(sudo base64 -w 0 $CERT_PATH)
ENCODED_KEY=$(sudo base64 -w 0 $KEY_PATH)

# .envファイルの特定の行を更新
sed -i "s|^SSL_CERTIFICATE=.*$|SSL_CERTIFICATE=$ENCODED_CERT|" "$ENV_FILE"
sed -i "s|^SSL_CERTIFICATE_KEY=.*$|SSL_CERTIFICATE_KEY=$ENCODED_KEY|" "$ENV_FILE"

# Dockerコンテナの再起動
cd /home/cobalt/deploy/Portfolio
docker compose -f deploy/docker-compose.yaml down
docker compose -f deploy/docker-compose.yaml build --no-cache
docker compose -f deploy/docker-compose.yaml up -d

# ログの記録
sudo sh -c 'echo "$(date): SSL certificates updated and containers restarted." >> /var/log/cert_update.log'
