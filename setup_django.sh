#!/bin/bash

# 必要なパッケージの更新とインストール
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv gunicorn nginx certbot python3-certbot-nginx

# Django のインストール
python3 -m pip install -r requirements.txt

echo "setup django success"
