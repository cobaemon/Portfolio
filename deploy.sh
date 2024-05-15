#!/bin/bash

set -e  # エラー時にスクリプトを終了する

# deployディレクトリ内のシェルスクリプトに実行権限を設定
echo "Setting execute permissions for deploy directory scripts..."
chmod +x deploy/encode-certs.sh
chmod +x deploy/setup.sh
chmod +x deploy/start-nginx.sh
chmod +x deploy/update-certs-and-restart-container.sh
chmod +x deploy/setup-iptables.sh

bash deploy/setup-iptables.sh

bash deploy/setup.sh

# 設定ファイルのコピー
echo "Copying configuration files..."
cp deploy/host_portfolio.conf /etc/nginx/conf.d/portfolio.conf

# 証明書のエンコードと配置
echo "Encoding and placing certificates..."
bash deploy/encode-certs.sh

# Dockerイメージのビルドとコンテナの起動
echo "Building Docker images and starting containers..."
bash deploy/update-certs-and-restart-container.sh

# Certbotのフックスクリプトにupdate-certs-and-restart-container.shを追加
echo "Adding Certbot hook..."
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo cp deploy/update-certs-and-restart-container.sh /etc/letsencrypt/renewal-hooks/deploy/
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/update-certs-and-restart-container.sh

# Nginxの再起動
echo "Restarting Nginx..."
sudo systemctl restart nginx

echo "Deployment completed successfully."