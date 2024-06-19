#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# Djangoのマイグレーションの実行
echo "Running Django migrations..."
python manage.py makemigrations accounts.CustomUser
python manage.py makemigrations otp_totp
python manage.py makemigrations

# OTP TOTPのマイグレーションを先に行う
python manage.py migrate otp_totp 0001_initial

# 残りのマイグレーションを行う
python manage.py migratepython manage.py collectstatic --noinput

# Gunicornを起動
exec "$@"
