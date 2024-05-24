#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
LIGHT_GREEN="\e[92m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリ
SCRIPT_DIR="/home/cobalt/deploy/Portfolio/deploy"

# 証明書と鍵のエンコードと.envファイルの更新
echo -e "${LIGHT_GREEN}Encoding certificates and updating .env file...${RESET}"
$SCRIPT_DIR/encode-certs.sh

# Nginxコンテナの名前を設定
NGINX_CONTAINER_NAME="portfolio-nginx"  # ここにNginxコンテナの名前を設定

# Nginxコンテナの再起動
echo -e "${LIGHT_GREEN}Reloading Nginx container...${RESET}"
# コンテナ内で環境変数を更新し、証明書をデコードして配置
docker exec $NGINX_CONTAINER_NAME bash -c "
    export SSL_CERTIFICATE=\$(grep SSL_CERTIFICATE $SCRIPT_DIR/.env | cut -d '=' -f2) &&
    export SSL_CERTIFICATE_KEY=\$(grep SSL_CERTIFICATE_KEY $SCRIPT_DIR/.env | cut -d '=' -f2) &&
    echo \$SSL_CERTIFICATE | base64 -d > /etc/ssl/certs/fullchain.pem &&
    echo \$SSL_CERTIFICATE_KEY | base64 -d > /etc/ssl/private/privkey.pem &&
    nginx -s reload
"
echo -e "${LIGHT_GREEN}Nginx container has been reloaded with the new certificates.${RESET}"
