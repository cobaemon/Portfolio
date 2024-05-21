#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
LIGHT_CYAN="\e[96m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Dockerコンテナの停止とシステムクリーンアップ
echo -e "${LIGHT_CYAN}Stopping Docker containers and pruning the system...${RESET}"
sudo docker compose -f deploy/docker-compose.yaml stop

# Dockerシステム全体のクリーンアップ
echo -e "${LIGHT_CYAN}Pruning Docker system...${RESET}"
sudo docker system prune -af

# Nginxキャッシュのクリア
echo -e "${LIGHT_CYAN}Clearing Nginx cache...${RESET}"
sudo rm -rf /var/cache/nginx/*

echo -e "${LIGHT_CYAN}Initialization completed successfully.${RESET}"
