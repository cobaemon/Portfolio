#!/bin/bash

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# OSを検出
if [ -f /etc/lsb-release ]; then
    # Ubuntu
    PKG_MANAGER="apt"
elif [ -f /etc/redhat-release ]; then
    # CentOS
    PKG_MANAGER="yum"
else
    echo "Unsupported OS"
    exit 1
fi

# 必要なパッケージの更新
sudo $PKG_MANAGER update -y

# Docker のインストール
if [ "$PKG_MANAGER" = "yum" ]; then
    # CentOS 7
    sudo $PKG_MANAGER install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo $PKG_MANAGER install -y docker-ce docker-ce-cli containerd.io
else
    # Ubuntu
    sudo $PKG_MANAGER install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo $PKG_MANAGER update
    sudo $PKG_MANAGER install -y docker-ce docker-ce-cli containerd.io
fi

# Docker サービスの開始と有効化
sudo systemctl start docker
sudo systemctl enable docker

echo "Docker installation and setup completed."

# Certbotのインストール
if [ "$OS" = "centos" ]; then
    sudo $PKG_MANAGER install -y epel-release
    sudo $PKG_MANAGER install -y certbot python2-certbot-nginx
elif [ "$OS" = "ubuntu" ]; then
    sudo $PKG_MANAGER install -y certbot python3-certbot-nginx
fi

# Nginxのインストール
if [ "$OS" = "centos" ]; then
    sudo $PKG_MANAGER install -y nginx
elif [ "$OS" = "ubuntu" ]; then
    sudo $PKG_MANAGER install -y nginx
fi

# Nginxを起動して有効化
sudo systemctl start nginx
sudo systemctl enable nginx

# Nginxの設定ファイルをコピー
sudo cp $SCRIPT_DIR/host_portfolio.conf /etc/nginx/conf.d/portfolio.conf

# Nginxのリロード
sudo systemctl reload nginx

# Certbotを使用して証明書を取得
sudo certbot --nginx -d portfolio.cobaemon.com --non-interactive --agree-tos -m your-email@example.com

echo "Docker, Nginx, and Certbot installation and setup completed."
