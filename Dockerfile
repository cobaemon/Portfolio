# Pythonイメージをベースにする
FROM python:3.10

# 環境変数を設定
ENV PYTHONUNBUFFERED=1
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8
ENV TZ Asia/Tokyo
ENV TERM xterm

# タイムゾーンの反映
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 作業ディレクトリを設定
RUN mkdir -p /app/logs
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

# CMD ["python", "manage.py", "runserver", "0.0.0.0:8000", "--settings=config.local_settings"]
