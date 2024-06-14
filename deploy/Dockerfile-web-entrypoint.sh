#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 環境変数の読み込み
if [ -f /app/.env ]; then
    echo "Loading environment variables from .env file..."
    set -a
    source /app/.env
    set +a
    rm /app/.env
fi

# Djangoのマイグレーションの実行
echo "Running Django migrations..."
python manage.py makemigrations
python manage.py migrate

# Gunicornを起動
exec "$@"
