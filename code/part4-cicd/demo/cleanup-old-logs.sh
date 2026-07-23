#!/bin/bash
# 清理 /tmp/app-logs/ 目錄下超過指定天數的舊 log 檔案
# 用途：示範 PR 審查工作流，腳本刻意保留幾個可改進點供 reviewer 指出

# 注意：未加 set -euo pipefail（遺漏最佳實踐）

# 保留天數（從第一個參數讀取，但沒有預設值保護）
DAYS=$1

# 硬編碼 log 目錄（應改為變數或可傳入參數）
LOG_DIR="/tmp/app-logs"

echo "開始清理 $LOG_DIR 中超過 $DAYS 天的 .log 檔案..."

# 注意：未先確認目錄是否存在就直接掃描
FILES_TO_DELETE=$(find "$LOG_DIR" -name "*.log" -mtime +"$DAYS")

if [ -z "$FILES_TO_DELETE" ]; then
    echo "沒有找到需要清理的舊 log 檔案。"
    exit 0
fi

# 計算要刪除的檔案數量
FILE_COUNT=$(echo "$FILES_TO_DELETE" | wc -l)

# 計算要刪除的總大小（KB）
TOTAL_SIZE=$(echo "$FILES_TO_DELETE" | xargs du -ck 2>/dev/null | tail -1 | awk '{print $1}')

echo "找到 $FILE_COUNT 個舊 log 檔案，總大小約 ${TOTAL_SIZE} KB"

# 刪除檔案（注意：沒有 -v 旗標，靜默刪除，無逐一確認）
echo "$FILES_TO_DELETE" | xargs rm

echo "清理完成：已刪除 $FILE_COUNT 個 .log 檔案，釋放約 ${TOTAL_SIZE} KB 空間。"
