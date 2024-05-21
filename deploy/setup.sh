#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
BLUE="\e[34m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# .envファイルの読み込み
set -a
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${BLUE}Loading environment variables from .env file...${RESET}"
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
echo -e "${BLUE}Updating package list...${RESET}"
sudo $PKG_MANAGER update -y

# Dockerのインストール
if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}Docker not found. Installing Docker...${RESET}"
    if [ "$PKG_MANAGER" = "yum" ]; then
        sudo $PKG_MANAGER install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo $PKG_MANAGER install -y docker-ce docker-ce-cli containerd.io
    else
        sudo $PKG_MANAGER install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo $PKG_MANAGER update
        sudo $PKG_MANAGER install -y docker-ce docker-ce-cli containerd.io
    fi
    sudo systemctl start docker
    sudo systemctl enable docker
    echo -e "${BLUE}Docker installation completed.${RESET}"
else
    echo -e "${BLUE}Docker is already installed.${RESET}"
fi

# Certbotのインストール
if ! command -v certbot &> /dev/null; then
    echo -e "${BLUE}Certbot not found. Installing Certbot...${RESET}"
    if [ "$PKG_MANAGER" = "yum" ]; then
        sudo $PKG_MANAGER install -y epel-release
        sudo $PKG_MANAGER install -y certbot python2-certbot-nginx
    elif [ "$PKG_MANAGER" = "apt" ]; then
        sudo $PKG_MANAGER install -y certbot python3-certbot-nginx
    fi
    echo -e "${BLUE}Certbot installation completed.${RESET}"
else
    echo -e "${BLUE}Certbot is already installed.${RESET}"
fi

# Nginxのインストール
if ! command -v nginx &> /dev/null; then
    echo -e "${BLUE}Nginx not found. Installing Nginx...${RESET}"
    sudo $PKG_MANAGER install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo -e "${BLUE}Nginx installation completed.${RESET}"
else
    echo -e "${BLUE}Nginx is already installed.${RESET}"
fi

# Nginxの設定ファイルをコピー
echo -e "${BLUE}Copying Nginx configuration files...${RESET}"
sudo cp -f "$SCRIPT_DIR/host_nginx.conf" /etc/nginx/nginx.conf
sudo cp -f "$SCRIPT_DIR/host_portfolio.conf" /etc/nginx/conf.d/portfolio.conf

# Nginxのリロード
echo -e "${BLUE}Reloading Nginx...${RESET}"
sudo systemctl reload nginx

# 証明書の存在を確認
echo -e "${BLUE}Checking for existing certificates...${RESET}"
if sudo certbot certificates --cert-name portfolio.cobaemon.com > /dev/null 2>&1; then
    echo -e "${BLUE}Updating existing certificate for portfolio.cobaemon.com...${RESET}"
    sudo certbot renew --cert-name portfolio.cobaemon.com
else
    echo -e "${BLUE}Obtaining new certificate for portfolio.cobaemon.com...${RESET}"
    sudo certbot --nginx -d portfolio.cobaemon.com --non-interactive --agree-tos -m "$EMAIL"
fi

echo -e "${BLUE}Setup script completed successfully.${RESET}"