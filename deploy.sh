#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# 実行権限の設定
echo -e "${GREEN}Setting execute permissions for deploy directory scripts...${RESET}"
chmod +x deploy/encode-certs.sh
chmod +x deploy/setup.sh
chmod +x deploy/start-nginx.sh
chmod +x deploy/update-certs-and-restart-container.sh
chmod +x deploy/initialization.sh
chmod +x deploy/finalize.sh
chmod +x deploy/setup_iptables.sh
chmod +x deploy/update_route53_record.sh
chmod +x deploy/update-nginx-cert.sh

# 初期化スクリプトの実行
echo -e "${GREEN}Running initialization script...${RESET}"
bash deploy/initialization.sh

# iptablesの設定を実行
echo -e "${GREEN}Running setup iptables script...${RESET}"
bash deploy/setup_iptables.sh

# setup.shスクリプトの実行
echo -e "${GREEN}Running setup script...${RESET}"
bash deploy/setup.sh

# 設定ファイルのコピー
echo -e "${GREEN}Copying Nginx configuration files...${RESET}"
sudo cp deploy/host_portfolio.conf /etc/nginx/conf.d/portfolio.conf

# 証明書のエンコードと配置
echo -e "${GREEN}Encoding and placing certificates...${RESET}"
bash deploy/encode-certs.sh

# Dockerイメージのビルドとコンテナの起動
echo -e "${GREEN}Building Docker images and starting containers...${RESET}"
bash deploy/update-certs-and-restart-container.sh

# Certbotフックの設定
echo -e "${GREEN}Setting up Certbot deploy hook...${RESET}"
sudo ln -sf /home/cobalt/deploy/Portfolio/deploy/update-nginx-cert.sh /etc/letsencrypt/renewal-hooks/deploy/update-nginx-cert.sh
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/update-nginx-cert.sh

# ファイナライズスクリプトの実行
echo -e "${GREEN}Running finalize script...${RESET}"
bash deploy/finalize.sh

echo -e "${GREEN}Deployment completed successfully.${RESET}"
