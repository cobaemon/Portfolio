#!/bin/bash

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo $SSL_CERTIFICATE | base64 -d > /etc/ssl/certs/fullchain.pem
echo $SSL_CERTIFICATE_KEY | base64 -d > /etc/ssl/private/privkey.pem

# Nginxをデーモンとして起動
nginx -g 'daemon off;'