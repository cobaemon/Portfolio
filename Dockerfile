# Pythonイメージをベースにする
FROM python:3.10-slim

# 環境変数を設定
ENV PYTHONUNBUFFERED=1
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8
ENV TZ JST-9
ENV TERM xterm

# 作業ディレクトリを設定
RUN mkdir /app
WORKDIR /app

# pipのアップグレード
RUN python -m pip install --upgrade pip

# 依存関係をコピー
COPY requirements.txt .
# 依存関係をインストール
RUN pip install --no-cache-dir -r requirements.txt

# アプリケーションコードをコピー
COPY . .

# 静的ファイルを収集
RUN python manage.py collectstatic --no-input

# CMD ["gunicorn", "--bind", "0.0.0.0:8000", "config.wsgi:application"]