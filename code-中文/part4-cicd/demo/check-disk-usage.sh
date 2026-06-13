#!/bin/bash
# 磁碟用量檢查腳本（auto-pilot demo 用途）
# 用法：./check-disk-usage.sh [目錄路徑]
# 注意：本腳本刻意保留三個可修復問題，供 AI 自動修復管線展示用

# 問題 1：刻意省略 set -euo pipefail（腳本遇錯不會中止）

THRESHOLD=1000

# 問題 2：$1 沒有預設值，若無參數 DIR 為空字串，du 會報錯
DIR=$1

# 取得指定目錄的磁碟用量（KB）
USAGE=$(du -sk "$DIR" | awk '{print $1}')

# 問題 3：使用字串比較 > 而非整數比較 -gt
# 在 bash 中 [ "$USAGE" > "$THRESHOLD" ] 實際上是把 $THRESHOLD 當作重新導向目標
# 這行永遠為 true，同時會在當前目錄產生一個名為 $THRESHOLD 值的空檔案
if [ "$USAGE" > "$THRESHOLD" ]; then
    echo "警告：$DIR 用量 ${USAGE} KB 超過閾值 ${THRESHOLD} KB"
else
    echo "正常：$DIR 用量 ${USAGE} KB，未超過閾值 ${THRESHOLD} KB"
fi
