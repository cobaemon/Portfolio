#!/bin/bash

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ENV_FILE="$SCRIPT_DIR/.env"

# 証明書と鍵のパス
CERT_PATH="/etc/letsencrypt/live/portfolio.cobaemon.com/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/portfolio.cobaemon.com/privkey.pem"

# Base64エンコード
ENCODED_CERT=$(base64 -w 0 $CERT_PATH)
ENCODED_KEY=$(base64 -w 0 $KEY_PATH)

# .envファイルの特定の行を更新
sudo sed -i "s|^SSL_CERTIFICATE=.*$|SSL_CERTIFICATE=$ENCODED_CERT|" "$ENV_FILE"
sudo sed -i "s|^SSL_CERTIFICATE_KEY=.*$|SSL_CERTIFICATE_KEY=$ENCODED_KEY|" "$ENV_FILE"
