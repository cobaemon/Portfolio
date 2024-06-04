#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
YELLOW="\e[33m"
RED="\e[91m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo -e "${YELLOW}Openssl Setup Start.${RESET}"

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

# 必要なパッケージのインストール
echo -e "${YELLOW}Installing dependencies...${RESET}"
if [ "$OS" = "ubuntu" ]; then
    sudo $PKG_MANAGER install -y build-essential checkinstall zlib1g-dev
elif [ "$OS" = "centos" ]; then
    sudo $PKG_MANAGER groupinstall -y "Development Tools"
    sudo $PKG_MANAGER install -y gcc perl-core make
fi

# OpenSSLのダウンロードとインストール
OPENSSL_VERSION="1.1.1k"
OPENSSL_DIR="/usr/local/src/openssl-$OPENSSL_VERSION"
if [ ! -d "$OPENSSL_DIR" ]; then
    echo -e "${YELLOW}Downloading OpenSSL $OPENSSL_VERSION...${RESET}"
    cd /usr/local/src
    sudo wget https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
    sudo tar -zxf openssl-$OPENSSL_VERSION.tar.gz
    cd openssl-$OPENSSL_VERSION

    echo -e "${YELLOW}Installing OpenSSL $OPENSSL_VERSION...${RESET}"
    sudo ./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl
    sudo make
    sudo make install

    echo -e "${YELLOW}Updating symbolic links...${RESET}"
    sudo mv /usr/bin/openssl /usr/bin/openssl.bak || true
    sudo ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl

    echo -e "${YELLOW}Updating library path...${RESET}"
    echo "/usr/local/openssl/lib" | sudo tee -a /etc/ld.so.conf.d/openssl-$OPENSSL_VERSION.conf
    sudo ldconfig
else
    echo -e "${YELLOW}OpenSSL $OPENSSL_VERSION is already installed.${RESET}"
fi

# インストールの確認
openssl version

echo -e "${YELLOW}Openssl Setup Successfully.${RESET}"
