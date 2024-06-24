#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo -e "${GREEN}Deploy Start.${RESET}"

# 実行権限の設定
echo -e "${GREEN}Setting execute permissions for deploy directory scripts...${RESET}"
chmod +x deploy/update-certs-and-restart-container.sh
chmod +x deploy/encode-certs.sh
chmod +x deploy/update-container-nginx-cert.sh
chmod +x deploy/update-route53-record.sh
chmod +x deploy/start-container-nginx.sh

chmod +x deploy/initialization.sh
chmod +x deploy/systemclock-setup.sh
chmod +x deploy/iptables-setup.sh
chmod +x deploy/docker-setup.sh
chmod +x deploy/certbot-setup.sh
chmod +x deploy/openssl-setup.sh
chmod +x deploy/nginx-setup.sh
chmod +x deploy/aws-cli-setup.sh
chmod +x deploy/fail2ban-setup.sh
chmod +x deploy/logrotate-setup.sh
chmod +x deploy/go-access-setup.sh
chmod +x deploy/finalize.sh

# 初期化
bash deploy/initialization.sh

# システムクロックの設定
bash deploy/systemclock-setup.sh

# iptablesのセットアップ
bash deploy/iptables-setup.sh

# dockerのセットアップ
bash deploy/docker-setup.sh

# certbotのセットアップ
bash deploy/certbot-setup.sh

# opensslのセットアップ
bash deploy/openssl-setup.sh

# nginxのセットアップ
bash deploy/nginx-setup.sh

# AWS CLIのセットアップ
bash deploy/aws-cli-setup.sh

# fail2banのセットアップ
bash deploy/fail2ban-setup.sh

# logrotateのセットアップ
bash deploy/logrotate-setup.sh

# GoAccessのセットアップ
bash deploy/go-access-setup.sh

# 最終処理
bash deploy/finalize.sh

echo -e "${GREEN}Deployment completed successfully.${RESET}"
