#!/usr/bin/env bash
set -euo pipefail
# cascade-start.sh：為平行 Claude 實例建立 3 個 git worktree
#
# 功能說明：
#   在專案根目錄平行建立 3 個 worktree，每個對應一個 Claude 實例，
#   分別負責不同面向的審查工作：
#     Worker 1 = code/part2-hooks/ 安全性審查
#     Worker 2 = 程式碼品質審查
#     Worker 3 = 規格合規性檢查
#
# 使用方式（從專案根目錄執行）：
#   bash code/part7-workflows/cascade/cascade-start.sh [task-name]
#
# 預設任務名稱：hooks-review

BASE_BRANCH=$(git branch --show-current)
TASK=${1:-"hooks-review"}
TS=$(date +%s)

echo "目前分支：${BASE_BRANCH}"
echo "任務名稱：${TASK}"
echo "開始建立 3 個 worktree..."
echo ""

for i in 1 2 3; do
  BRANCH="${TASK}-worker-${i}-${TS}"
  DIR="../work-${TASK}-${i}"

  if git worktree add "$DIR" -b "$BRANCH" HEAD; then
    echo "✓ Worktree $i 建立成功：$DIR（分支：$BRANCH）"
  else
    echo "✗ Worktree $i 建立失敗：$DIR（分支：$BRANCH）" >&2
    exit 1
  fi
done

echo ""
echo "=== 啟動 Claude 實例指令 ==="
echo "Worker 1（安全性審查）：cd ../work-${TASK}-1 && claude"
echo "Worker 2（程式碼品質）：cd ../work-${TASK}-2 && claude"
echo "Worker 3（規格合規）：  cd ../work-${TASK}-3 && claude"

echo ""
echo "=== 完成後清理 worktree 指令 ==="
echo "git worktree remove ../work-${TASK}-1"
echo "git worktree remove ../work-${TASK}-2"
echo "git worktree remove ../work-${TASK}-3"
echo "git worktree prune"
