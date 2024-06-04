#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
LIGHTGREEN="\e[92m"
RED="\e[31m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# .envファイルの読み込み
set -a
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${LIGHTGREEN}Loading environment variables from .env file...${RESET}"
    source "$SCRIPT_DIR/.env"
else
    echo -e "${RED}.env file not found. Please ensure it exists in the script directory.${RESET}"
    exit 1
fi
set +a

# AWS CLIプロファイルの設定
AWS_CREDENTIALS_FILE="$HOME/.aws/credentials"
AWS_CONFIG_FILE="$HOME/.aws/config"

# AWSプロファイルの設定を確認して更新
if ! grep -q "^\[$AWS_PROFILE\]" "$AWS_CREDENTIALS_FILE" 2>/dev/null; then
    echo -e "${LIGHTGREEN}Creating AWS CLI credentials profile: $AWS_PROFILE${RESET}"
    mkdir -p ~/.aws
    cat >> "$AWS_CREDENTIALS_FILE" <<EOL
[$AWS_PROFILE]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOL
else
    echo -e "${LIGHTGREEN}AWS CLI credentials profile $AWS_PROFILE already exists.${RESET}"
fi

if ! grep -q "^\[profile $AWS_PROFILE\]" "$AWS_CONFIG_FILE" 2>/dev/null; then
    echo -e "${LIGHTGREEN}Creating AWS CLI config profile: $AWS_PROFILE${RESET}"
    mkdir -p ~/.aws
    cat >> "$AWS_CONFIG_FILE" <<EOL
[profile $AWS_PROFILE]
region = $AWS_DEFAULT_REGION
EOL
else
    echo -e "${LIGHTGREEN}AWS CLI config profile $AWS_PROFILE already exists.${RESET}"
fi

# 現在のパブリックIPアドレスを取得
echo -e "${LIGHTGREEN}Fetching current public IP address...${RESET}"
PUBLIC_IP=$(curl -s https://api.ipify.org)

# 現在のRoute 53のAレコードを取得
echo -e "${LIGHTGREEN}Fetching current A record for $DOMAIN_NAME from Route 53...${RESET}"
CURRENT_IP=$(aws route53 list-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID \
    --query "ResourceRecordSets[?Name == '${DOMAIN_NAME}.'].ResourceRecords[0].Value" \
    --output text \
    --profile $AWS_PROFILE)

# IPアドレスが異なる場合のみ更新
echo -e "${LIGHTGREEN}$(date '+%Y/%m/%d/%H/%M/%S')${RESET}"
if [ "$PUBLIC_IP" != "$CURRENT_IP" ]; then
    echo -e "${LIGHTGREEN}Public IP has changed. Updating Route 53 A record...${RESET}"
    CHANGE_BATCH=$(cat <<EOF
{
    "Comment": "Auto updating public IP",
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "$DOMAIN_NAME",
            "Type": "A",
            "TTL": 3600,
            "ResourceRecords": [{"Value": "$PUBLIC_IP"}]
        }
    }]
}
EOF
)
    aws route53 change-resource-record-sets \
        --hosted-zone-id $HOSTED_ZONE_ID \
        --change-batch "$CHANGE_BATCH" \
        --profile $AWS_PROFILE

    echo -e "${LIGHTGREEN}Updated A record from $CURRENT_IP to $PUBLIC_IP${RESET}"
else
    echo -e "${LIGHTGREEN}No change in IP address${RESET}"
fi
