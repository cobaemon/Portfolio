#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# .envファイルの読み込み
set -a
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${YELLOW}Loading environment variables from .env file...${RESET}"
    source "$SCRIPT_DIR/.env"
else
    echo -e "${RED}.env file not found. Please ensure it exists in the script directory.${RESET}"
    exit 1
fi
set +a

# Nginxの再起動
echo -e "${YELLOW}Restarting Nginx...${RESET}"
sudo systemctl restart nginx

# docker composeの実行
echo -e "${YELLOW}docker compose build and up...${RESET}"
docker compose -f deploy/docker-compose.yaml build --no-cache
docker compose -f deploy/docker-compose.yaml up -d

# 運用ユーザーの作成
echo -e "${YELLOW}Creating operational user in PostgreSQL...${RESET}"
docker exec -i portfolio-db psql -U ${POSTGRES_USER} <<-EOSQL
  CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
  CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
  GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOSQL
echo -e "${YELLOW}Operational user created successfully.${RESET}"

# Cronjobでパブリックアドレスの変更を自動でドメインに反映
# Cronジョブの設定
CRON_JOB="0 * * * * /home/cobalt/deploy/Portfolio/deploy/update-route53-record.sh >> /var/log/portfolio/update-route53-record.log 2>&1"
(crontab -l 2>/dev/null | grep -F "$CRON_JOB" || (crontab -l 2>/dev/null; echo "$CRON_JOB")) | crontab -

echo -e "${YELLOW}Finalize completed successfully.${RESET}"
