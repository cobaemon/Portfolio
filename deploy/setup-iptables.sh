#!/bin/sh

# 既存のルールをクリア
iptables -F
iptables -X

# 必要なモジュールのロード
modprobe xt_conntrack
modprobe nf_conntrack

# デフォルトポリシーを設定
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# DOCKERチェーンの手動作成（既に存在する場合はスキップ）
iptables -N DOCKER 2>/dev/null

# HTTPおよびHTTPSトラフィックの許可
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Dockerインターフェースへのトラフィックの許可
iptables -A FORWARD -o docker0 -j DOCKER
iptables -A FORWARD -i docker0 -j ACCEPT
iptables -A FORWARD -o br-918b2a66b087 -j DOCKER

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

systemctl restart docker

echo "Success iptable setup"
