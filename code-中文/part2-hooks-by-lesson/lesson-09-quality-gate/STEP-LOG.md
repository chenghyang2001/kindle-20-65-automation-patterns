# 第 9 課演練記錄：quality-gate.sh

> 範例檔：`quality/quality-gate.sh`
> demo 腳本：`quality-gate-demo.sh`（修改：log 路徑 + 使用 demo 目錄）
> 事件：**Stop**（Claude Code 每次停止回應前）｜ 難度：⭐⭐⭐
> 主題：AI 做完事之前先自我把關 — 擋下有未 commit 變更的 session

---

## 核心觀念

```
正常流程：Stop 事件觸發 → quality-gate.sh 跑 → exit 0 → Claude 結束
防護流程：Stop 事件觸發 → 偵測到 git 有未 commit 變更 → block JSON → Claude 被阻止結束 + 強制提醒
```

**Stop hook 的 block 格式**：和第 8 課 Settings-change 一樣，用扁平 `{"decision":"block","reason":"..."}` JSON + exit 0。
不是 PreToolUse 的巢狀 `hookSpecificOutput`（第 6 課），也不是單純 exit 2（第 4 課）。

---

## Step 1：乾淨狀態 — 安靜放行

**命令：**

```bash
git status --short
echo '{"stop_reason": "end_turn"}' | bash quality/demo-quality-gate/quality-gate-demo.sh
echo $?
```

**目的：** 確認 working tree 乾淨時 quality-gate 安靜放行。
**預期：** `git status` 無輸出、exit 0、stdout 空白。
**實際驗證：** ✅ 全部沉默，三個都空。Stop hook 的設計哲學：「沒問題就不打擾你」。

---

## Step 2：製造未追蹤新檔案 — 發現盲點

**命令：**

```bash
echo "測試未存檔" > quality/demo-quality-gate/dirty.txt
echo '{"stop_reason": "end_turn"}' | bash quality/demo-quality-gate/quality-gate-demo.sh
echo $?
# 清理
rm quality/demo-quality-gate/dirty.txt
```

**目的：** 看 quality-gate 能不能偵測未存的新檔案。
**預期（事前）：** 以為會 block。
**實際驗證：** ⚠️ **exit 0（盲點！）**

`dirty.txt` 是全新未追蹤檔案（git status 顯示 `??`），但腳本只用：

```bash
UNCOMMITTED=$(git diff --name-only 2>/dev/null)    # 已追蹤檔案的修改
STAGED=$(git diff --name-only --cached 2>/dev/null) # 已 git add 的暫存
```

| 指令 | 看得見 | 看不見 |
|------|--------|--------|
| `git diff --name-only` | 已追蹤檔案的改動 | **未追蹤新檔案（??）** |
| `git diff --cached` | git add 暫存 | 未追蹤新檔案 |
| `git status --porcelain` | **全部（含 ??）** | — |

→ 和第 4、8 課同教訓：精確比對有「換個角度就漏」的盲點。修法：改用 `git status --porcelain | grep -v '^??'` 或把 `??` 也納入。

---

## Step 3：修改已追蹤檔案 — 觸發 block

**命令：**

```bash
echo "# 測試改動" >> quality/auto-format.sh
echo '{"stop_reason": "end_turn"}' | bash quality/demo-quality-gate/quality-gate-demo.sh
echo $?
# 清理
git checkout quality/auto-format.sh
```

**目的：** 修改已追蹤的檔案，讓 `git diff` 真的看到，觸發 block。
**預期：** stdout 吐 block JSON + exit 0。
**實際驗證：** ✅

```json
{
  "decision": "block",
  "reason": "1. 偵測到未 commit 的變更"
}
```

exit code = 0。block 決定在 JSON 裡，不在 exit code — 和第 8 課 audit-config 同格式，和第 4 課 exit 2 完全不同。

---

## Step 4：stop_hook_active 防無限迴圈

**命令：**

```bash
# A. 帶防護旗標 → 直接提前離場
echo '{"stop_reason": "end_turn", "stop_hook_active": true}' | bash quality/demo-quality-gate/quality-gate-demo.sh
echo $?

# B. 清理，確認 working tree 乾淨
rm -f quality/demo-quality-gate/dirty.txt
git status --short
```

**目的：** 理解 `stop_hook_active` 為何存在。
**預期：** A → 無輸出 + exit 0；B → 乾淨。
**實際驗證：** ✅ A 沉默 exit 0；B git status 無輸出。

**為什麼需要這個旗標：**

```
Claude Code 停止 → 觸發 Stop hook → hook 回傳 block → Claude 再次嘗試停止
→ 再次觸發 Stop hook → 再次 block → ... 無限迴圈
```

Claude Code 在「因 hook block 被迫繼續」的情況下再次嘗試停止時，會把 `stop_hook_active: true` 注入 payload，腳本第 6 行偵測到後直接 exit 0，打破迴圈。這是「防護網的防護網的防護網」。

---

## 第 9 課四 Step 對照

| Step | 情境 | 結果 | 關鍵原因 |
|------|------|------|---------|
| 1 | 乾淨狀態 | 沉默 exit 0 | 無問題不打擾 |
| 2 | 新建未追蹤檔（`??`） | **exit 0（盲點）** | `git diff` 不認 `??` |
| 3 | 修改已追蹤檔 | block JSON + exit 0 | `git diff` 看見了 |
| 4 | `stop_hook_active: true` | 沉默 exit 0 | 防護旗標提前離場 |

**三種 block 格式對照（四課集齊）：**

| 課 | 事件 | 格式 | exit code |
|----|------|------|-----------|
| 第 4 課 | PreToolUse（Bash） | `exit 2`（無 JSON） | 2 |
| 第 6 課 | PreToolUse（MCP） | `{hookSpecificOutput:{permissionDecision}}` | 0 |
| 第 8 課 | Settings-change | `{decision, reason}` | 0 |
| 第 9 課 | Stop | `{decision, reason}` | 0 |

**產出物：** `quality-gate-demo.sh`
