#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Nginxの再起動
echo -e "${YELLOW}Restarting Nginx...${RESET}"
sudo systemctl restart nginx

# docker composeの実行
echo -e "${YELLOW}docker compose build and up...${RESET}"
docker compose -f deploy/docker-compose.yaml build --no-cache
docker compose -f deploy/docker-compose.yaml up -d

# Cronjobでパブリックアドレスの変更を自動でドメインに反映
# Cronジョブの設定
CRON_JOB="0 * * * * /home/cobalt/deploy/Portfolio/deploy/update-route53-record.sh >> /var/log/portfolio/update-route53-record.log 2>&1"
(crontab -l 2>/dev/null | grep -F "$CRON_JOB" || (crontab -l 2>/dev/null; echo "$CRON_JOB")) | crontab -

echo -e "${YELLOW}Finalize completed successfully.${RESET}"
