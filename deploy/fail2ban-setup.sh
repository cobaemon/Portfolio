#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo -e "${YELLOW}Fail2ban Setup Start.${RESET}"

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

# fail2banのインストール
echo -e "${YELLOW}Installing Fail2ban...${RESET}"
if [ "$OS" = "ubuntu" ]; then
    sudo $PKG_MANAGER install -y fail2ban
elif [ "$OS" = "centos" ]; then
    sudo $PKG_MANAGER install -y epel-release
    sudo $PKG_MANAGER install -y fail2ban
fi

# fail2banの設定ファイルを作成または確認
echo -e "${YELLOW}Setting up Fail2ban configuration...${RESET}"
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# fail2banの設定ファイルをコピー（存在する場合）
CUSTOM_JAIL_CONF="/home/cobalt/deploy/Portfolio/deploy/jail.conf"
if [ -f "$CUSTOM_JAIL_CONF" ]; then
    echo -e "${YELLOW}Copying custom Fail2ban configuration...${RESET}"
    sudo cp "$CUSTOM_JAIL_CONF" /etc/fail2ban/jail.local
fi

# nginx-404フィルタの設定を追加
NGINX_404_FILTER="/etc/fail2ban/filter.d/nginx-404.conf"
if [ ! -f "$NGINX_404_FILTER" ]; then
    echo -e "${YELLOW}Creating nginx-404 filter...${RESET}"
    sudo bash -c 'cat <<EOT > /etc/fail2ban/filter.d/nginx-404.conf
[Definition]
failregex = ^<HOST> - .* "(GET|POST|HEAD) .* HTTP.*" 404
ignoreregex =
EOT'
fi

# nginx-400フィルタの設定を追加
NGINX_400_FILTER="/etc/fail2ban/filter.d/nginx-400.conf"
if [ ! -f "$NGINX_400_FILTER" ]; then
    echo -e "${YELLOW}Creating nginx-400 filter...${RESET}"
    sudo bash -c 'cat <<EOT > /etc/fail2ban/filter.d/nginx-400.conf
[Definition]
failregex = ^<HOST> - .* "(GET|POST|HEAD|PUT|DELETE|PATCH|OPTIONS) .* HTTP.*" 400
ignoreregex =
EOT'
fi

# nginx-noscriptフィルタの設定を追加
NGINX_NOSCRIPT_FILTER="/etc/fail2ban/filter.d/nginx-noscript.conf"
if [ ! -f "$NGINX_NOSCRIPT_FILTER" ]; then
    echo -e "${YELLOW}Creating nginx-noscript filter...${RESET}"
    sudo bash -c 'cat <<EOT > /etc/fail2ban/filter.d/nginx-noscript.conf
[Definition]
failregex = ^<HOST> - .* "(GET|POST) .*\.php.* HTTP.*" 404
            ^<HOST> - .* "(GET|POST) .*\.exe.* HTTP.*" 404
            ^<HOST> - .* "(GET|POST) .*\.pl.* HTTP.*" 404
ignoreregex =
EOT'
fi

# nginx-proxyフィルタの設定を追加
NGINX_PROXY_FILTER="/etc/fail2ban/filter.d/nginx-proxy.conf"
if [ ! -f "$NGINX_PROXY_FILTER" ]; then
    echo -e "${YELLOW}Creating nginx-proxy filter...${RESET}"
    sudo bash -c 'cat <<EOT > /etc/fail2ban/filter.d/nginx-proxy.conf
[Definition]
failregex = ^<HOST> - .* "(GET|POST) .* HTTP.*" 403
ignoreregex =
EOT'
fi

# nginx-limit-reqフィルタの設定を追加
NGINX_LIMIT_REQ_FILTER="/etc/fail2ban/filter.d/nginx-limit-req.conf"
if [ ! -f "$NGINX_LIMIT_REQ_FILTER" ]; then
    echo -e "${YELLOW}Creating nginx-limit-req filter...${RESET}"
    sudo bash -c 'cat <<EOT > /etc/fail2ban/filter.d/nginx-limit-req.conf
[Definition]
failregex = ^<HOST> - .* "(GET|POST) .* HTTP.*" 503
ignoreregex =
EOT'
fi

# fail2banの再起動
echo -e "${YELLOW}Restarting Fail2ban...${RESET}"
sudo systemctl restart fail2ban

echo -e "${YELLOW}Fail2ban Setup Successfully.${RESET}"
