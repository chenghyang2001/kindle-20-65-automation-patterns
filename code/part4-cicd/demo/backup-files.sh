#!/bin/bash
# backup-files.sh - 將來源目錄備份至目標目錄下以時間戳命名的子目錄
# 用法: ./backup-files.sh <src_dir> <dest_dir>

# Critical #4：嚴格錯誤防護，任一步失敗即中止，避免誤判備份成功
set -euo pipefail

# Critical #1：檢查必要參數，避免變數為空時誤操作家目錄等位置
if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
    echo "Usage: $0 <src_dir> <dest_dir>" >&2
    exit 1
fi

SRC_DIR=$1
DEST_DIR=$2

# Warning #3：加上時分秒避免同日多次執行時覆蓋既有備份
DATE=$(date +%Y-%m-%d_%H%M%S)
BACKUP_DIR="$DEST_DIR/backup-$DATE"

# Warning #4：顯式建立備份目錄，避免依賴 cp 的隱式行為
mkdir -p "$BACKUP_DIR"

# Critical #2：所有變數加上雙引號，避免空白或特殊字元造成 word-splitting / globbing
# Warning #1：只保留遞迴備份一種策略，移除原本與 find 迴圈互相覆蓋的扁平複製邏輯
cp -r "$SRC_DIR" "$BACKUP_DIR"

# Critical #3：以 find -print0 + while read -d '' 安全處理含空白或換行的檔名
# Warning #2：此處僅用於統計 .log/.conf 檔案數量，不再執行第二次複製，避免結構混亂
COUNT=0
while IFS= read -r -d '' _; do
    COUNT=$((COUNT + 1))
done < <(find "$SRC_DIR" \( -name "*.log" -o -name "*.conf" \) -print0)

echo "已備份完成（含 $COUNT 個 .log/.conf 檔案）到 $BACKUP_DIR"
exit 0
