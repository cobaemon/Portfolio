#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
RED="\e[91m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo -e "${YELLOW}Nginx Setup Start.${RESET}"

# OSを検出
if [ -f /etc/lsb-release ]; then
    # Ubuntu
    PKG_MANAGER="apt"
    OS="ubuntu"
elif [ -f /etc/redhat-release ]; then
    # CentOS
    PKG_MANAGER="yum"
    OS="centos"
else
    echo -e "${RED}Unsupported OS${RESET}"
    exit 1
fi

# 必要なパッケージの更新
echo -e "${YELLOW}Updating package list...${RESET}"
sudo $PKG_MANAGER update -y

# Nginxのインストール
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}Nginx not found. Installing Nginx...${RESET}"
    sudo $PKG_MANAGER install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo -e "${YELLOW}Nginx installation completed.${RESET}"
else
    echo -e "${YELLOW}Nginx is already installed.${RESET}"
fi

# Nginxの設定ファイルをコピー
echo -e "${YELLOW}Copying Nginx configuration files...${RESET}"
sudo cp -f "$SCRIPT_DIR/host_nginx.conf" /etc/nginx/nginx.conf
sudo cp -f "$SCRIPT_DIR/host_portfolio.conf" /etc/nginx/conf.d/portfolio.conf

# Nginxのリロード
echo -e "${YELLOW}Reloading Nginx...${RESET}"
sudo systemctl reload nginx

echo -e "${YELLOW}Nginx Setup Successfully.${RESET}"
