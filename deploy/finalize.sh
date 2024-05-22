#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
LIGHT_MAGENTA="\e[95m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Certbotのフックスクリプトにupdate-certs-and-restart-container.shを追加
echo -e "${LIGHT_MAGENTA}Adding Certbot deployment hook...${RESET}"
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo cp "$SCRIPT_DIR/update-certs-and-restart-container.sh" /etc/letsencrypt/renewal-hooks/deploy/
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/update-certs-and-restart-container.sh

# Nginxの再起動
echo -e "${LIGHT_MAGENTA}Restarting Nginx...${RESET}"
sudo systemctl restart nginx

echo -e "${LIGHT_MAGENTA}Finalize completed successfully.${RESET}"

# Cronjobでパブリックアドレスの変更を自動でドメインに反映
bash update_route53_record.sh
