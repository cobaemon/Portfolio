#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo -e "${YELLOW}AWS CLI Setup Start.${RESET}"

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

# AWS CLIのインストール
if ! command -v aws &> /dev/null; then
    echo -e "${YELLOW}AWS CLI not found. Installing AWS CLI...${RESET}"
    if [ "$PKG_MANAGER" = "yum" ]; then
        sudo $PKG_MANAGER install -y awscli
    elif [ "$PKG_MANAGER" = "apt" ]; then
        sudo $PKG_MANAGER install -y awscli
    fi
    echo -e "${YELLOW}AWS CLI installation completed.${RESET}"
else
    echo -e "${YELLOW}AWS CLI is already installed.${RESET}"
fi

echo -e "${YELLOW}AWS CLI Setup Successfully.${RESET}"
