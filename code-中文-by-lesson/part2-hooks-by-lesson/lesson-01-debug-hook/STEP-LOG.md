# 第 1 課演練記錄：debug-hook.sh

> 範例檔：`settings-examples/debug-hook.sh`（+ `hooks-overview.json`）
> demo 腳本：`debug-hook-demo.sh`（唯一修改：log 從 `/tmp/...` 改寫到本 demo 目錄的 `hook-debug.log`）
> 事件：任意事件都能掛 ｜ 難度：⭐
> 主題：學會「看見」Hook 收到了什麼（stdin → JSON → exit code）

---

## 核心觀念

Hook 三要素：


1. **事件（Event）**：掛在什麼時間點（PreToolUse / PostToolUse / Stop / SessionStart…）
2. **輸入（stdin）**：Claude 把「現在發生什麼」打包成 JSON 從 stdin 餵進來
3. **輸出（exit code / stdout）**：`exit 0` 放行、`exit 2` 阻擋

---

## Step 1：餵第一包假 JSON，確認「放行」


**下的命令：**

```bash
echo '{"hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": {"command": "ls -la"}}' | bash demo/debug-hook-demo.sh
echo $?
```

**目的：** 冒充 Claude Code，把一包「我準備執行 Bash 指令」的事件塞給 hook，理解 hook 的基本管線。

**預期效果：** exit code = 0（debug hook 永遠放行），畫面無輸出（東西寫進 log 檔）。

**實際驗證結果：** ✅ `exit code = 0`，畫面一片安靜。stdout 保持乾淨 = 好事（避免污染 Claude 解析通道）。

---

## Step 2：打開 log 檔，親眼看 hook「錄」到了什麼


**下的命令：**

```bash
cat demo/hook-debug.log
```

**目的：** 確認 hook 把輸入 JSON 完整記錄下來，看清「事件公文格式」。


**預期效果：** log 內含時間戳 + `EVENT: PreToolUse` + 被 `jq '.'` 美化排版的完整 JSON。

**實際驗證結果：** ✅ log 三段對應腳本三行：

- `=== 時間戳 ===` ← `echo "=== $(date) ==="`
- `EVENT: PreToolUse` ← `jq -r '.hook_event_name'`（`-r` = 不帶引號）
- 縮排美化的 JSON ← `jq '.'`（原樣輸出但排版）

---


## Step 3：換兩種不同事件，看日誌累積

**下的命令：**

```bash
echo '{"hook_event_name": "PostToolUse", "tool_name": "Write", "tool_input": {"file_path": "src/app.ts"}}' | bash demo/debug-hook-demo.sh
echo '{"hook_event_name": "Stop", "stop_hook_active": false}' | bash demo/debug-hook-demo.sh
```


**目的：** 觀察不同事件的 JSON 欄位結構不一樣（寫 hook 前必須先知道有哪些欄位可用）。

**預期效果：** log 用 `>>` 附加累積三筆，三種事件欄位各異。

**實際驗證結果：** ✅ 三種事件欄位明顯不同：

- `PreToolUse` / `PostToolUse`：有 `tool_name` + `tool_input`
- `Stop`：只有 `stop_hook_active`（**沒有 tool_input**）→ 第 9 課無限迴圈煞車就靠它


---

## Step 4：餵「缺欄位」的壞 JSON，看邊界行為

**下的命令：**

```bash
echo '{"foo": "bar"}' | bash demo/debug-hook-demo.sh
tail -7 demo/hook-debug.log
```

**目的：** 觀察 jq 挖不到欄位時的行為，理解後續所有「防禦性寫法」的必要性。

**預期效果：** log 出現 `EVENT: null`，腳本不崩潰但留下垃圾值。

**實際驗證結果：** ✅ `EVENT: null` + exit 0。jq 挖不到欄位回傳字串 `null`，**不會炸但會把垃圾值流到下游** → 這是第 2 課 `// "unknown"`、第 3 課 `// empty` 防禦的伏筆。

---

## 帶走的重點

| 技能 | 步驟 |
|------|------|
| `INPUT=$(cat)` 讀 stdin 起手式 | 全程 |
| `echo '假JSON' \| bash hook.sh` 手動測試法（Pattern 22 黃金法則） | Step 1 |
| exit 0 = 放行；stdout 保持乾淨是美德 | Step 1 |
| 不同事件有不同欄位（三種表單） | Step 3 |
| 缺欄位 → `null` 垃圾值，需防禦寫法 | Step 4 |

**產出物：** `debug-hook-demo.sh`、`hook-debug.log`（4 筆紀錄）
