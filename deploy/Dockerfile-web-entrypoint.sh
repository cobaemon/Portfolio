#!/bin/bash

# エラー時にスクリプトを終了する
set -e

git reset --hard
git pull origin $BRANCH_NAME

# Djangoのマイグレーションの実行
echo "Running Django migrations..."
python manage.py makemigrations
python manage.py migrate

# Gunicornを起動
exec "$@"
