#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo -e "${YELLOW}Systemclock Setup Start.${RESET}"

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

echo -e "${YELLOW}Installing Chrony...${RESET}"
if [ "$OS" == "ubuntu" ]; then
    sudo $PKG_MANAGER install -y chrony
elif [ "$OS" == "centos" ]; then
    sudo $PKG_MANAGER install -y chrony
fi

# Chronyのサービスを開始し、永続化
echo -e "${YELLOW}Enabling and starting Chrony service...${RESET}"
sudo systemctl enable chronyd
sudo systemctl start chronyd

# タイムゾーンを東京に変更
echo -e "${YELLOW}Changing timezone to Asia/Tokyo...${RESET}"
sudo timedatectl set-timezone Asia/Tokyo

# NTPの有効化
echo -e "${YELLOW}Enabling NTP synchronization...${RESET}"
sudo timedatectl set-ntp true

# Chronyのステータスを確認
echo -e "${YELLOW}Chrony status:${RESET}"
sudo chronyc tracking

echo -e "${YELLOW}Systemclock Setup Successfully.${RESET}"
