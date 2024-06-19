#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# Djangoのマイグレーションの実行
echo "Running Django migrations..."
python manage.py makemigrations
python manage.py migrate otp_totp
python manage.py migrate
python manage.py collectstatic --noinput

# Gunicornを起動
exec "$@"
