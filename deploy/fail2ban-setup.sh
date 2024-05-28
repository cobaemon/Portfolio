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

# フィルタの設定を追加
create_filter() {
    local filter_path=$1
    local filter_content=$2
    if [ ! -f "$filter_path" ]; then
        echo -e "${YELLOW}Creating $(basename "$filter_path") filter...${RESET}"
        sudo bash -c "cat <<EOT > $filter_path
$filter_content
EOT"
    fi
}

# フィルタ設定
create_filter "/etc/fail2ban/filter.d/nginx-404.conf" "
[Definition]
failregex = ^<HOST> - .* \"(GET|POST|HEAD) .* HTTP.*\" 404
ignoreregex =
"

create_filter "/etc/fail2ban/filter.d/nginx-400.conf" "
[Definition]
failregex = ^<HOST> - .* \"(GET|POST|HEAD|PUT|DELETE|PATCH|OPTIONS) .* HTTP.*\" 400
ignoreregex =
"

create_filter "/etc/fail2ban/filter.d/nginx-noscript.conf" "
[Definition]
failregex = ^<HOST> - .* \"(GET|POST) .*\\.php.* HTTP.*\" 404
            ^<HOST> - .* \"(GET|POST) .*\\.exe.* HTTP.*\" 404
            ^<HOST> - .* \"(GET|POST) .*\\.pl.* HTTP.*\" 404
ignoreregex =
"

create_filter "/etc/fail2ban/filter.d/nginx-proxy.conf" "
[Definition]
failregex = ^<HOST> - .* \"(GET|POST) .* HTTP.*\" 403
ignoreregex =
"

create_filter "/etc/fail2ban/filter.d/nginx-limit-req.conf" "
[Definition]
failregex = ^<HOST> - .* \"(GET|POST) .* HTTP.*\" 503
ignoreregex =
"

# fail2banの再起動
echo -e "${YELLOW}Restarting Fail2ban...${RESET}"
sudo systemctl restart fail2ban

echo -e "${YELLOW}Fail2ban Setup Successfully.${RESET}"
