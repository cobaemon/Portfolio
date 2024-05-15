#!/bin/sh

# 既存のルールをクリア
iptables -F
iptables -X

# HTTPおよびHTTPSトラフィックの許可
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Dockerインターフェースへのトラフィックの許可
iptables -A FORWARD -o docker0 -j ACCEPT
iptables -A FORWARD -i docker0 -j ACCEPT

# ホストのNginxからコンテナのNginxへの通信を許可
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 4433 -j ACCEPT

# ループバックインターフェースのトラフィックを許可
iptables -A INPUT -i lo -j ACCEPT

# 既に確立された接続を許可
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ping (ICMP echo requests) を許可
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# その他のトラフィックを拒否
iptables -A INPUT -j DROP

# Dockerインターフェースを有効化
ip link set docker0 up

# iptablesルールの保存
service iptables save

# iptablesサービスの再起動
service iptables restart

echo "Success iptable setup"
