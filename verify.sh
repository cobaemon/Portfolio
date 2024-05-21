#!/bin/bash

# エラー時にスクリプトを終了する
set -e

# 色の定義
LIGHT_YELLOW="\e[93m"
LIGHT_GREEN="\e[92m"
LIGHT_RED="\e[91m"
RESET="\e[0m"

# スクリプトのディレクトリを基準にパスを設定
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# 検証結果の集計変数
total_tests=0
success_count=0
failure_count=0

# 検証スクリプトの実行関数
run_test() {
    total_tests=$((total_tests + 1))
    if bash "$1"; then
        success_count=$((success_count + 1))
    else
        failure_count=$((failure_count + 1))
    fi
}

# 各検証スクリプトの実行
echo -e "${LIGHT_YELLOW}Running referrer policy verification...${RESET}"
run_test "$SCRIPT_DIR/validation/verify_referrer_policy.sh"

# 検証結果の集計表示
echo -e "${LIGHT_YELLOW}All verification tests completed.${RESET}"
echo -e "${LIGHT_GREEN}Success: $success_count/$total_tests${RESET}"
echo -e "${LIGHT_RED}Failure: $failure_count/$total_tests${RESET}"

# 終了ステータスの設定
if [ $failure_count -ne 0 ]; then
    exit 1
else
    exit 0
fi
