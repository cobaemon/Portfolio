#!/bin/bash

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# .envファイルの読み込み
set -a
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "Loading environment variables from .env file..."
    source "$SCRIPT_DIR/.env"
else
    echo ".env file not found. Please ensure it exists in the script directory."
    exit 1
fi
set +a

# メールアドレスの取得
EMAIL=${DEFAULT_TO_EMAIL:-}
if [ -z "$EMAIL" ]; then
  echo "Email address not set in .env file. Please set DEFAULT_TO_EMAIL in .env."
  exit 1
fi

if [ -z "$EMAIL" ]; then
  echo "Email address not set in .env file. Please set DEFAULT_TO_EMAIL in .env."
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
    echo "Unsupported OS"
    exit 1
fi

# 必要なパッケージの更新
echo "Updating package list..."
sudo $PKG_MANAGER update -y

# Dockerのインストール
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
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
    echo "Docker installation completed."
else
    echo "Docker is already installed."
fi

# Certbotのインストール
if ! command -v certbot &> /dev/null; then
    echo "Certbot not found. Installing Certbot..."
    if [ "$PKG_MANAGER" = "yum" ]; then
        sudo $PKG_MANAGER install -y epel-release
        sudo $PKG_MANAGER install -y certbot python2-certbot-nginx
    elif [ "$PKG_MANAGER" = "apt" ]; then
        sudo $PKG_MANAGER install -y certbot python3-certbot-nginx
    fi
    echo "Certbot installation completed."
else
    echo "Certbot is already installed."
fi

# Nginxのインストール
if ! command -v nginx &> /dev/null; then
    echo "Nginx not found. Installing Nginx..."
    sudo $PKG_MANAGER install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo "Nginx installation completed."
else
    echo "Nginx is already installed."
fi

# Nginxの設定ファイルをコピー
echo "Copying Nginx configuration files..."
sudo cp -f "$SCRIPT_DIR/host_nginx.conf" /etc/nginx/nginx.conf
sudo cp -f "$SCRIPT_DIR/host_portfolio.conf" /etc/nginx/conf.d/portfolio.conf

# Nginxのリロード
echo "Reloading Nginx..."
sudo systemctl reload nginx

# # Gettextのインストール
# if ! command -v msgfmt &> /dev/null || [ "$(msgfmt --version | head -n1 | awk '{print $4}')" \< "0.15" ]; then
#     echo "Installing or upgrading Gettext..."
#     if [ "$PKG_MANAGER" = "yum" ]; then
#         sudo $PKG_MANAGER install -y gettext
#     elif [ "$PKG_MANAGER" = "apt" ]; then
#         sudo $PKG_MANAGER install -y gettext
#     fi
#     echo "Gettext installation completed."
# else
#     echo "Gettext is already installed and up-to-date."
# fi

# 証明書の存在を確認
echo "Checking for existing certificates..."
if sudo certbot certificates --cert-name portfolio.cobaemon.com > /dev/null 2>&1; then
    echo "Updating existing certificate for portfolio.cobaemon.com..."
    sudo certbot renew --cert-name portfolio.cobaemon.com
else
    echo "Obtaining new certificate for portfolio.cobaemon.com..."
    sudo certbot --nginx -d portfolio.cobaemon.com --non-interactive --agree-tos -m "$EMAIL"
fi

echo "Setup script completed successfully."