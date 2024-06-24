#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo -e "${YELLOW}GoAccess Real-Time Setup Start.${RESET}"

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

# GoAccessのインストール
echo -e "${YELLOW}Installing GoAccess...${RESET}"
if [ "$OS" = "ubuntu" ]; then
    sudo apt-get install -y goaccess gzip
elif [ "$OS" = "centos" ]; then
    sudo yum install -y goaccess gzip
fi

echo -e "${YELLOW}GoAccess installation completed.${RESET}"

# ログファイルのパスを指定
LOG_DIR="/var/log/nginx"
REPORT_DIR="/var/log/portfolio"
REPORT_FILE="$REPORT_DIR/report.html"

# レポートディレクトリの作成
echo -e "${YELLOW}Creating report directory if it does not exist...${RESET}"
sudo mkdir -p $REPORT_DIR

# 圧縮ログファイルを一時ディレクトリに解凍
TEMP_LOG_DIR=$(mktemp -d)
echo -e "${YELLOW}Decompressing log files...${RESET}"
find $LOG_DIR -name "host_nginx_portfolio_https_access.log-*.gz" -exec gunzip -c {} \; > $TEMP_LOG_DIR/uncompressed_logs.log

# 圧縮されていないログファイルを連結
find $LOG_DIR -name "host_nginx_portfolio_https_access.log" -exec cat {} + >> $TEMP_LOG_DIR/uncompressed_logs.log

# ポートが既に使用されているか確認し、使用されている場合はプロセスを終了
check_and_kill_port() {
    local port=$1
    if lsof -i:$port >/dev/null; then
        echo -e "${YELLOW}Port $port is in use. Terminating the process using this port...${RESET}"
        fuser -k $port/tcp
    fi
}

# WebSocketサーバーのポートを確認し、必要なら終了
check_and_kill_port 7890

# GoAccessをバックグラウンドで実行してリアルタイムレポートを生成
echo -e "${YELLOW}Generating GoAccess real-time report...${RESET}"
nohup goaccess $TEMP_LOG_DIR/uncompressed_logs.log -o $REPORT_FILE --log-format='%h - %^ [%d:%t %^] "%r" %s %b "%R" "%u"' --real-time-html --ws-url=ws://localhost:7890 --date-format='%d/%b/%Y' --time-format='%H:%M:%S' &

# ローカルサーバーのポートを確認し、必要なら終了
check_and_kill_port 8888

# ローカルサーバーでレポートを表示
echo -e "${YELLOW}Starting local server to display the report on port 8888...${RESET}"
cd $REPORT_DIR
nohup python3 -m http.server 8888 &

# 一時ディレクトリを削除
rm -rf $TEMP_LOG_DIR

echo -e "${YELLOW}GoAccess real-time setup and report generation completed. Report available at http://localhost:8888/report.html.${RESET}"
