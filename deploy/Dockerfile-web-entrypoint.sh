#!/bin/bash

# エラー時にスクリプトを終了する
set -e

git reset --hard
git pull origin $BRANCH_NAME

psql -U ${POSTGRES_USER} <<-EOSQL
  CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
  CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
  GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOSQL

# Djangoのマイグレーションの実行
echo "Running Django migrations..."
python manage.py makemigrations
python manage.py migrate

# Gunicornを起動
exec "$@"
