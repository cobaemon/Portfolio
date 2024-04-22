#!/bin/bash

# 必要なパッケージの更新とインストール
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv

# Django のインストール
python3 -m pip install -r requirements.txt

# Django 開発サーバーの起動（ポート 8000 で待機）
echo "setup django success"
