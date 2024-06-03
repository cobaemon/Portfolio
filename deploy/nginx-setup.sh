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

# 既存のパッケージ版Nginxを削除
if command -v nginx &> /dev/null; then
    echo -e "${YELLOW}Removing existing package version of Nginx...${RESET}"
    sudo $PKG_MANAGER remove -y nginx
fi

# 必要なパッケージのインストール
echo -e "${YELLOW}Installing dependencies...${RESET}"
if [ "$OS" = "ubuntu" ]; then
    sudo $PKG_MANAGER install -y build-essential checkinstall zlib1g-dev libpcre3 libpcre3-dev unzip
elif [ "$OS" = "centos" ]; then
    sudo $PKG_MANAGER groupinstall -y "Development Tools"
    sudo $PKG_MANAGER install -y pcre pcre-devel zlib zlib-devel make
fi

# Nginxのソースコードとインストール
NGINX_VERSION="1.20.1"
NGINX_DIR="/usr/local/src/nginx-$NGINX_VERSION"
if [ ! -d "$NGINX_DIR" ]; then
    echo -e "${YELLOW}Downloading Nginx $NGINX_VERSION...${RESET}"
    cd /usr/local/src
    sudo wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
    sudo tar -zxvf nginx-$NGINX_VERSION.tar.gz

    echo -e "${YELLOW}Installing Nginx $NGINXVERSION...${RESET}"
    cd nginx-$NGINX_VERSION
    sudo ./configure --with-http_ssl_module --with-openssl=/usr/local/src/openssl-$OPENSSL_VERSION
    sudo make
    sudo make install
else
    echo -e "${YELLOW}Nginx $NGINX_VERSION is already installed.${RESET}"
fi

# 必要なディレクトリとファイルの作成
echo -e "${YELLOW}Setting up necessary directories and files...${RESET}"
sudo mkdir -p /etc/nginx
sudo cp /usr/local/nginx/conf/mime.types /etc/nginx/mime.types

# シンボリックリンクの更新
echo 'export PATH=$PATH:/usr/local/nginx/sbin' >> ~/.bashrc
source ~/.bashrc

# systemdユニットファイルの作成
NGINX_SERVICE="/etc/systemd/system/nginx.service"
if [ ! -f "$NGINX_SERVICE" ]; then
    echo -e "${YELLOW}Creating systemd unit file for Nginx...${RESET}"
    sudo bash -c 'cat << EOF > /etc/systemd/system/nginx.service
[Unit]
Description=A high performance web server and a reverse proxy server
After=network.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF'
fi

# systemdデーモンのリロード
sudo systemctl daemon-reload

# Nginxサービスの起動と有効化
sudo systemctl start nginx
sudo systemctl enable nginx

# Nginxの設定ファイルをコピー
echo -e "${YELLOW}Copying Nginx configuration files...${RESET}"
sudo cp -f "$SCRIPT_DIR/host_nginx.conf" /usr/local/nginx/conf/nginx.conf
sudo cp -f "$SCRIPT_DIR/host_portfolio.conf" /usr/local/nginx/conf/portfolio.conf

# Nginxの設定テストとリロード
echo -e "${YELLOW}Testing and reloading Nginx...${RESET}"
sudo nginx -t && sudo systemctl reload nginx

echo -e "${YELLOW}Nginx Setup Successfully.${RESET}"
