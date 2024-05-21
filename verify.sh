#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
LIGHT_YELLOW="\e[93m"
LIGHT_RED="\e[91m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# 検証スクリプトの実行
echo -e "${LIGHT_YELLOW}Running referrer policy verification...${RESET}"
bash "$SCRIPT_DIR/validation/verify_referrer_policy.sh"

echo -e "${LIGHT_YELLOW}All verification tests completed.${RESET}"
