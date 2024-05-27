#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo -e "${YELLOW}Certbot Setup Start.${RESET}"

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

# メールアドレスの取得
EMAIL=${DEFAULT_TO_EMAIL:-}
if [ -z "$EMAIL" ]; then
    echo -e "${RED}Email address not set in .env file. Please set DEFAULT_TO_EMAIL in .env.${RESET}"
    exit 1
fi

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

# Certbotのインストール
if ! command -v certbot &> /dev/null; then
    echo -e "${YELLOW}Certbot not found. Installing Certbot...${RESET}"
    if [ "$PKG_MANAGER" = "yum" ]; then
        sudo $PKG_MANAGER install -y epel-release
        sudo $PKG_MANAGER install -y certbot python2-certbot-nginx
    elif [ "$PKG_MANAGER" = "apt" ]; then
        sudo $PKG_MANAGER install -y certbot python3-certbot-nginx
    fi
    echo -e "${YELLOW}Certbot installation completed.${RESET}"
else
    echo -e "${YELLOW}Certbot is already installed.${RESET}"
fi

# 証明書の存在を確認
echo -e "${YELLOW}Checking for existing certificates...${RESET}"
if sudo certbot certificates --cert-name portfolio.cobaemon.com > /dev/null 2>&1; then
    echo -e "${YELLOW}Updating existing certificate for portfolio.cobaemon.com...${RESET}"
    sudo certbot renew --cert-name portfolio.cobaemon.com
else
    echo -e "${YELLOW}Obtaining new certificate for portfolio.cobaemon.com...${RESET}"
    sudo certbot --nginx -d portfolio.cobaemon.com --non-interactive --agree-tos -m "$EMAIL"
fi

# 証明書を暗号化し.envを更新
sudo ./encode-certs.sh

# Certbotのフックスクリプトにupdate-certs-and-restart-container.shを追加
echo -e "${YELLOW}Adding Certbot deployment hook...${RESET}"
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo cp "$SCRIPT_DIR/update-certs-and-restart-container.sh" /etc/letsencrypt/renewal-hooks/deploy/
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/update-certs-and-restart-container.sh

echo -e "${YELLOW}Certbot Setup Successfully.${RESET}"
