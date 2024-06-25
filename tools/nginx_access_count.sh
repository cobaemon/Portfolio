#!/bin/bash

# ログファイルのパス（ワイルドカードで指定して圧縮ファイルも含む）
log_files_pattern="/var/log/nginx/host_nginx_portfolio_https_access.log*"

# 正規アクセスと不正アクセスの判定条件
is_valid_access() {
    if [[ "$1" == "200" || "$1" == "301" || "$1" == "302" ]]; then
        return 0
    else
        return 1
    fi
}

# コマンドライン引数の解析
while getopts 's:m:H:D:W:M:Y:' OPTION; do
    case "$OPTION" in
        s) seconds=$OPTARG ;;
        m) minutes=$OPTARG ;;
        H) hours=$OPTARG ;;
        D) days=$OPTARG ;;
        W) weeks=$OPTARG ;;
        M) months=$OPTARG ;;
        Y) years=$OPTARG ;;
        *) echo "Usage: $0 [-s seconds] [-m minutes] [-H hours] [-D days] [-W weeks] [-M months] [-Y years]"; exit 1 ;;
    esac
done

# 解析対象期間の計算
end_date=$(date +%s)
start_date=$end_date

if [ -n "$seconds" ]; then
    start_date=$((end_date - seconds))
fi
if [ -n "$minutes" ]; then
    start_date=$((end_date - minutes * 60))
fi
if [ -n "$hours" ]; then
    start_date=$((end_date - hours * 3600))
fi
if [ -n "$days" ]; then
    start_date=$((end_date - days * 86400))
fi
if [ -n "$weeks" ]; then
    start_date=$((end_date - weeks * 604800))
fi
if [ -n "$months" ]; then
    start_date=$((end_date - months * 2592000)) # おおよその月の日数を30日として計算
fi
if [ -n "$years" ]; then
    start_date=$((end_date - years * 31536000)) # おおよその年の日数を365日として計算
fi

# アクセス数のカウント
total_access_count=0
valid_access_count=0
invalid_access_count=0

# ログファイルの解析
for log_file in $log_files_pattern; do
    if [[ "$log_file" =~ \.gz$ ]]; then
        open_func="gunzip -c"
    else
        open_func="cat"
    fi

    $open_func "$log_file" | while read -r line; do
        # 日付を含む行のみを対象とする
        if [[ "$line" =~ \[([0-9]{2}/[a-zA-Z]{3}/[0-9]{4}:[0-9]{2}:[0-9]{2}:[0-9]{2})\ [+-][0-9]{4}\] ]]; then
            log_date_str=${BASH_REMATCH[1]}
            log_date=$(date -d "$log_date_str" +%s 2>/dev/null)

            if [ -n "$log_date" ] && [ "$log_date" -ge "$start_date" ] && [ "$log_date" -le "$end_date" ]; then
                # ステータスコードを抽出
                status_code=$(echo "$line" | awk '{print $9}')
                total_access_count=$((total_access_count + 1))
                if is_valid_access "$status_code"; then
                    valid_access_count=$((valid_access_count + 1))
                else
                    invalid_access_count=$((invalid_access_count + 1))
                fi
            fi
        fi
    done
done

# 比率の計算
if [ "$total_access_count" -gt 0 ]; then
    valid_ratio=$(echo "scale=2; $valid_access_count * 100 / $total_access_count" | bc)
    invalid_ratio=$(echo "scale=2; $invalid_access_count * 100 / $total_access_count" | bc)
else
    valid_ratio=0
    invalid_ratio=0
fi

# 結果の表示
start_date_str=$(date -d "@$start_date" '+%Y-%m-%d %H:%M:%S')
end_date_str=$(date -d "@$end_date" '+%Y-%m-%d %H:%M:%S')

echo "指定期間: $start_date_str - $end_date_str"
echo "トータルアクセス数: $total_access_count"
echo "正規アクセス数: $valid_access_count ($valid_ratio%)"
echo "不正アクセス数: $invalid_access_count ($invalid_ratio%)"
