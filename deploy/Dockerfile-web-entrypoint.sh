#!/bin/bash

# エラー時にスクリプトを終了する
set -e

git reset --hard
git pull origin $BRANCH_NAME

# Djangoのマイグレーションの実行
echo "Running Django migrations..."
python manage.py makemigrations
python manage.py migrate

# 残りのマイグレーションを行う
python manage.py migratepython manage.py collectstatic --noinput

# Gunicornを起動
exec "$@"
