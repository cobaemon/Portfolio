#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo -e "${YELLOW}iptables Setup Start.${RESET}"

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

# iptablesのインストール
echo -e "${YELLOW}Installing iptables...${RESET}"
if [ "$OS" = "ubuntu" ]; then
    sudo $PKG_MANAGER install -y iptables
elif [ "$OS" = "centos" ]; then
    sudo $PKG_MANAGER install -y iptables-services
fi

# firewalldの停止と無効化
if [ "$OS" = "centos" ]; then
    echo -e "${YELLOW}Disabling firewalld...${RESET}"
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
fi

# iptablesサービスの有効化と開始
if [ "$OS" = "centos" ]; then
    echo -e "${YELLOW}Enabling and starting iptables...${RESET}"
    sudo systemctl enable iptables
    sudo systemctl start iptables
fi

echo -e "${YELLOW}Initialization iptables...${RESET}"
# 既存のルールをクリア
iptables -F
iptables -X

# 必要なモジュールのロード
modprobe xt_conntrack
modprobe nf_conntrack

# デフォルトポリシーを設定
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# DOCKERチェーンの手動作成（既に存在する場合はスキップ）
iptables -N DOCKER 2>/dev/null

# HTTPおよびHTTPSトラフィックの許可
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Dockerインターフェースへのトラフィックの許可
iptables -A FORWARD -o docker0 -j DOCKER
iptables -A FORWARD -i docker0 -j ACCEPT
iptables -A FORWARD -o br-918b2a66b087 -j DOCKER

# ループバックインターフェースのトラフィックを許可
iptables -A INPUT -i lo -j ACCEPT

# 既に確立された接続を許可
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ping (ICMP echo requests) を許可
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# その他のトラフィックを拒否
iptables -A INPUT -j DROP

# Dockerインターフェースを有効化
ip link set docker0 up

# iptablesルールの保存
service iptables save

# iptablesサービスの再起動
service iptables restart

systemctl restart docker

echo -e "${YELLOW}iptables Setup Successfully.${RESET}"
