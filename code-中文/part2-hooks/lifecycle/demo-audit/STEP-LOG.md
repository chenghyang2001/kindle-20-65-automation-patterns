# 第 8 課演練記錄：audit-config.sh

> 範例檔：`lifecycle/audit-config.sh`
> demo 腳本：`audit-config-demo.sh`（修改：log 路徑從 `.claude/config-audit.log` 改到本 demo 目錄）
> demo 目錄：`lifecycle/demo-audit/`（與第 7 課 `demo-save-restore/` 分開）
> 事件：設定檔變更類｜ 難度：⭐⭐⭐
> 主題：誰動了我的設定檔 — 稽核 + 防護網的防護網

---

## 核心觀念

一明一暗兩件事：

1. **稽核（明）**：任何設定檔被動到，log 留一行「時間 | 來源 | 檔案」
2. **阻擋（暗）**：被改的是 `settings.json` → 輸出 `{decision: block}` 擋下

**為何 settings.json 要特別保護**：所有安全 hook 登記在 settings.json，被偷改移除 hook = 整套防護網連根拔起且不自覺 → 這支是「防護網的防護網」。

**新 JSON 格式**：用 `{decision, reason}`（與第 6 課 PreToolUse 的 `permissionDecision` 不同）。

---

## Step 1：一般設定檔被動 — 只稽核不阻擋

**命令：**

```bash
echo '{"source": "user_settings", "file_path": "/home/user/.bashrc"}' | bash lifecycle/demo-audit/audit-config-demo.sh
echo $?
cat lifecycle/demo-audit/config-audit.log
```

**目的：** 看「稽核但不擋路」。
**預期：** log 多一行，exit 0 不阻擋。
**實際驗證：** ✅ exit 0，stdout 空白（只記 log，沒有 block JSON）。log 累積型（append）新增 `2026-06-14 08:07:22 | user_settings | /home/user/.bashrc`，舊歷史保留。腳本先無條件記 log（`tee -a`），再判斷 source；user_settings 不符 → 阻擋跳過。即使放行，稽核軌跡已留下。

---

## Step 2：settings.json 被外部改 — 觸發阻擋

**命令：**

```bash
echo '{"source": "project_settings", "file_path": "/app/.claude/settings.json"}' | bash lifecycle/demo-audit/audit-config-demo.sh
echo $?
tail -2 lifecycle/demo-audit/config-audit.log
```

**目的：** 看防護網啟動，稽核與阻擋同時發生。
**預期：** stderr 警告 + `decision: block` JSON + log 也記一筆。
**實際驗證：** ✅ 兩件事同發：

- stderr：`偵測到設定檔遭外部修改：/app/.claude/settings.json`
- stdout：`{"decision":"block","reason":"偵測到 settings.json 遭外部修改。請先檢視變更內容再繼續。"}`（**扁平格式**，對比第 6 課的巢狀 hookSpecificOutput）
- exit code = 0（決定在 JSON 裡，呼應第 6 課）
- log 同步記下 `2026-06-14 08:08:26 | project_settings | /app/.claude/settings.json`
- **「先記錄、後判斷」**：即使觸發 block，證據已留下（擋不住至少留痕 = 縱深）
- 攻擊鏈：AI 想繞過安全 hook → 改 settings.json 移除它 → 改的動作本身被 audit 擋下 + 留證

---

## Step 3：稽核日誌累積 — 證據鏈

**命令：**

```bash
for payload in \
  '{"source":"project_settings","file_path":"/app/.claude/settings.json"}' \
  '{"source":"user_settings","file_path":"/home/user/.zshrc"}' \
  '{"source":"mcp_config","file_path":"/app/.mcp.json"}' \
  '{"source":"project_settings","file_path":"/app/.claude/settings.local.json"}' \
  '{"source":"local_settings","file_path":"/totally/different/path/settings.json"}'; do
  echo "$payload" | bash lifecycle/demo-audit/audit-config-demo.sh 2>/dev/null
  echo "exit $?"
done
tail -6 lifecycle/demo-audit/config-audit.log
```

**目的：** 看 log 累積成可追溯的稽核軌跡。
**預期：** 只有 settings.json 那筆 BLOCK，其餘放行；log 累積。
**實際驗證：** ✅ 5 筆只 1 筆 BLOCK，log 累積 7 筆（按時間排序的證據鏈）。
**發現盲點：** `settings.local.json` ✅ 放行 ← 它也是 Claude Code 設定檔（放本機覆寫設定），改它一樣影響行為，但 `basename != "settings.json"` 溜過。

- 與第 4 課同教訓：字串精確比對（`==`）有「同類不同名」漏網之魚

---

## Step 4：兩種 block 格式對照 + 大小寫邊界測試

**命令：**

```bash
# A. 兩課 block 格式並排
echo '{"source":"project_settings","file_path":"/app/.claude/settings.json"}' | bash lifecycle/demo-audit/audit-config-demo.sh 2>/dev/null
echo '{"tool_name":"mcp__filesystem__write","tool_input":{"path":"/app/.env"}}' | bash security/demo/mcp-write-guard-demo.sh 2>/dev/null
# B. 大小寫邊界測試
echo '{"source":"project_settings","file_path":"/app/.claude/Settings.json"}' | bash lifecycle/demo-audit/audit-config-demo.sh 2>/dev/null; echo $?
echo '{"source":"project_settings","file_path":"/app/.claude/settings.JSON"}' | bash lifecycle/demo-audit/audit-config-demo.sh 2>/dev/null; echo $?
echo '{"source":"project_settings","file_path":"/totally/different/path/settings.json"}' | bash lifecycle/demo-audit/audit-config-demo.sh 2>/dev/null; echo $?
```

**目的：** 釐清「同是擋，格式為何不同」+ 找更多盲點。
**預期：** 兩格式不同；大小寫變體可能漏。
**實際驗證：** ✅

**A. 兩種 block 格式：**

| | 第 8 課 | 第 6 課 |
|---|---|---|
| 格式 | `{decision, reason}`（扁平）| `{hookSpecificOutput:{permissionDecision, ...}}`（巢狀）|
| 擋的字 | `decision:"block"` | `permissionDecision:"deny"` |
| 事件 | 設定變更類 | PreToolUse |

→ **暗坑：不同事件用不同 JSON 格式，套錯沒反應。寫前要查該事件支援的欄位**（第 6 課特地寫 `hookEventName` 標注身分）。

**B. 邊界測試：**

| 檔案 | 結果 |
|------|:---:|
| `/app/.claude/settings.json` | 🛡️ BLOCK |
| `/totally/different/path/settings.json` | 🛡️ BLOCK（只認檔名不認路徑 = 優點）|
| `Settings.json`（大寫 S）| ✅ 放行 ⚠️ 大小寫盲點 |
| `settings.JSON`（大寫副檔名）| ✅ 放行 ⚠️ 大小寫盲點 |

→ Windows/macOS 大小寫不敏感檔案系統上，`Settings.json` = `settings.json` 同一檔，但 `==` 認為不同 → 攻擊者改大小寫即繞過。修法：比對前 `tr '[:upper:]' '[:lower:]'` 轉小寫。

---

## 第 8 課三個盲點總結（字串精確比對的極限）

| 盲點 | 範例 | 對應課 |
|------|------|--------|
| 同類不同名 | `settings.local.json` | Step 3 |
| 大小寫 | `Settings.json` / `settings.JSON` | Step 4 |
| （第 4 課）變形 | `rm -fr /`、`rm  -rf  /` | 第 4 課 |

→ 全部指向：**死字串規則擋不住「換個寫法的同一件事」** = 第 10 課 AI 語意判斷要解決的核心。

**產出物：** `audit-config-demo.sh`、`config-audit.log`（7 筆稽核軌跡）
