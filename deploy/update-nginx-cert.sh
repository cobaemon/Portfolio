#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# ログファイルの定義
LOGFILE="/home/cobalt/deploy/Portfolio/logs/update-nginx-cert.log"

# ログ出力関数の定義
log() {
    echo -e "$1" | tee -a "$LOGFILE"
}

# スクリプトのディレクトリを基準にパスを設定（絶対パスで設定）
SCRIPT_DIR="/home/cobalt/deploy/Portfolio/deploy"

# 証明書と鍵のエンコードと.envファイルの更新
log "${GREEN}Encoding certificates and updating .env file...${RESET}"
bash $SCRIPT_DIR/encode-certs.sh 2>&1 | tee -a "$LOGFILE"

# 環境変数の読み込み（ホスト側で実行）
SSL_CERTIFICATE=$(grep ^SSL_CERTIFICATE= $SCRIPT_DIR/.env | cut -d '=' -f2)
SSL_CERTIFICATE_KEY=$(grep ^SSL_CERTIFICATE_KEY= $SCRIPT_DIR/.env | cut -d '=' -f2)

# Nginxコンテナの再起動
NGINX_CONTAINER_NAME="portfolio-nginx"  # ここにNginxコンテナの名前を設定
log "${GREEN}Reloading Nginx container with new certificates...${RESET}"

# コンテナ内で環境変数を設定し、証明書をデコードして配置
docker exec $NGINX_CONTAINER_NAME bash -c "
    echo $SSL_CERTIFICATE | base64 -d > /etc/ssl/certs/fullchain.pem &&
    echo $SSL_CERTIFICATE_KEY | base64 -d > /etc/ssl/private/privkey.pem &&
    nginx -s reload
" 2>&1 | tee -a "$LOGFILE"

log "${GREEN}Nginx container has been reloaded with the new certificates.${RESET}"
