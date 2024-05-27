#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo -e "${YELLOW}Initialization Start.${RESET}"

# Dockerのインストール確認
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Skipping Docker-related steps.${RESET}"
else
    # Docker composeファイルの存在確認
    if [ -f "$SCRIPT_DIR/docker-compose.yaml" ]; then
        echo -e "${YELLOW}Stopping Docker containers and pruning the system...${RESET}"
        sudo docker compose -f "$SCRIPT_DIR/deploy/docker-compose.yaml" stop

        echo -e "${YELLOW}Pruning Docker system...${RESET}"
        sudo docker system prune -af
    else
        echo -e "${RED}Docker compose file not found. Skipping Docker-related steps.${RESET}"
    fi
fi

# Nginxのキャッシュディレクトリの存在確認
if [ -d /var/cache/nginx ]; then
    echo -e "${YELLOW}Clearing Nginx cache...${RESET}"
    sudo rm -rf /var/cache/nginx/*
else
    echo -e "${RED}Nginx cache directory not found. Skipping Nginx cache clearing.${RESET}"
fi

echo -e "${YELLOW}Initialization Successfully.${RESET}"
