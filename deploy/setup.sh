#!/bin/bash

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# .envファイルの読み込み
set -a
[ -f "$SCRIPT_DIR/.env" ] && source "$SCRIPT_DIR/.env"
set +a

# メールアドレスの取得
EMAIL=$DEFAULT_TO_EMAIL

if [ -z "$EMAIL" ]; then
  echo "Email address not set in .env file. Please set DEFAULT_TO_EMAIL in .env."
  exit 1
fi

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

# コピー先ディレクトリを設定
DEST_DIR="/var/www/html/errors"

# コピー先ディレクトリが存在しない場合に作成
if [ ! -d "$DEST_DIR" ]; then
    sudo mkdir -p "$DEST_DIR"
fi
# カスタムエラーページのコピー
sudo cp -r "$SCRIPT_DIR/errors/"* "$DEST_DIR"

# Nginxの設定ファイルをコピー
sudo cp $SCRIPT_DIR/host_nginx.conf /etc/nginx/nginx.conf
sudo cp $SCRIPT_DIR/host_portfolio.conf /etc/nginx/conf.d/portfolio.conf

# Nginxのリロード
sudo systemctl reload nginx

# 証明書の存在を確認
if sudo certbot certificates --cert-name portfolio.cobaemon.com > /dev/null 2>&1; then
    # 証明書が存在する場合は更新
    echo "Updating existing certificate for portfolio.cobaemon.com..."
    sudo certbot renew --cert-name portfolio.cobaemon.com
else
    # 証明書が存在しない場合は新規取得
    echo "Obtaining new certificate for portfolio.cobaemon.com..."
    sudo certbot --nginx -d portfolio.cobaemon.com --non-interactive --agree-tos -m "$EMAIL"
fi
echo "Docker, Nginx, and Certbot installation and setup completed."
