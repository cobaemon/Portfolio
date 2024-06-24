#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo -e "${YELLOW}Logrotate Configuration Script Start.${RESET}"

# ログローテーション設定ファイルの作成/更新
create_logrotate_config() {
    local filepath=$1
    local config=$2
    if [ -f "$filepath" ]; then
        echo -e "${YELLOW}既存の設定ファイルを更新します: $filepath${RESET}"
    else
        echo -e "${YELLOW}新しい設定ファイルを作成します: $filepath${RESET}"
    fi
    echo "$config" | sudo tee "$filepath" > /dev/null
}

# ログローテーション設定の内容
fail2ban_config="
/var/log/fail2ban.log {
    daily
    rotate 365
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
"

nginx_config="
/var/log/nginx/*.log {
    daily
    rotate 365
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
    endscript
}
"

portfolio_config="
/var/log/portfolio/*.log {
    daily
    rotate 365
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
"

# 設定ファイルのパス
fail2ban_path="/etc/logrotate.d/fail2ban"
nginx_path="/etc/logrotate.d/nginx"
portfolio_path="/etc/logrotate.d/portfolio"

# ログローテーション設定ファイルの作成/更新
create_logrotate_config "$fail2ban_path" "$fail2ban_config"
create_logrotate_config "$nginx_path" "$nginx_config"
create_logrotate_config "$portfolio_path" "$portfolio_config"

echo -e "${YELLOW}Logrotate Configuration Script Completed.${RESET}"
