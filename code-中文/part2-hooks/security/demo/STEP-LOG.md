# 第 4 課 + 第 6 課演練記錄（security/demo 共用目錄）

> 本目錄含兩課：
>
>
> - 第 4 課 `block-dangerous.sh` → demo：`block-dangerous-demo.sh`（零修改）
> - 第 6 課 `mcp-write-guard.sh` → demo：`mcp-write-guard-demo.sh`（零修改）

---

# 第 4 課：block-dangerous.sh

> 事件：`PreToolUse`（matcher = `Bash`）｜ 難度：⭐⭐
> 主題：本章核心 — exit 2 攔截機制 + 字串比對的天花板

## 核心觀念

| 退出碼 | 意義 | Claude 反應 |
|:---:|------|------------|
| exit 0 | 放行 | 照常執行 |
| exit 2 | 阻擋 | 不執行 + stderr 訊息塞回給 Claude 逼它換做法（自我修正迴圈）|

---

## Step 1：餵災難指令 rm -rf / — 看 exit 2 攔截

**命令：**

```bash

echo '{"tool_input": {"command": "rm -rf /"}}' | bash demo/block-dangerous-demo.sh; echo $?
```

**目的：** 看本章核心的 exit 2 攔截。
**預期：** 阻擋訊息 + exit 2。
**實際驗證：** ✅ `已阻擋：'rm -rf /' 是被禁止的指令` + exit 2。stderr 訊息會被注入 AI 上下文 → 不需人類介入的自我修正迴圈。`grep -qF` 的 `-F` 把 pattern 當純文字避免 regex 誤判。

---

## Step 2：餵無辜指令 — 確認不誤傷

**命令：**

```bash

echo '{"tool_input": {"command": "ls -la"}}' | bash demo/block-dangerous-demo.sh; echo $?
echo '{"tool_input": {"command": "git status"}}' | bash demo/block-dangerous-demo.sh; echo $?
echo '{"tool_input": {"command": "rm old-report.txt"}}' | bash demo/block-dangerous-demo.sh; echo $?
```

**目的：** 驗證黑名單精準度，不過度防禦。
**預期：** 三個都 exit 0。
**實際驗證：** ✅ 全放行。重點：**`rm` 本身沒被封殺**，只擋 `rm -rf /`、`rm -rf ~`（不可逆大範圍災難）。刪單一檔案是正常日常操作。三段式風險分級：無害放行、灰色問人、災難擋死。

---

## Step 3：七大危險指令全面掃射

**命令：** 把 7 個黑名單 pattern + 2 個變化型逐條餵入（heredoc 迴圈）。
**目的：** 一次看完整個防禦矩陣。
**預期：** 7 個 pattern 全擋。
**實際驗證：** ✅ 9 發全擋，但發現兩個教學點：

- `sudo rm -rf / --no-preserve-root` 被擋 → 子字串比對「一條罩一族」的**紅利**
- `git push --force-with-lease` 被擋 → ⚠️ **誤傷友軍！**（force push 的安全版，因含 `git push --force` 子字串被一併擋）
- 為何 `git push --force` 和 `git push -f` 要列兩條：不同字串，字串工具沒有「語意」，同義詞須逐條列舉

---

## Step 4：滲透測試 — 親手繞過防線

**命令：** 9 種繞過技巧（大小寫 / 空格 / 旗標拆分 / 旗標順序 / 小寫 SQL / 完整路徑 / base64 混淆 / 子目錄 / 變數隱藏）。

```bash
echo '{"tool_input":{"command":"RM -RF /"}}' | bash security/demo/block-dangerous-demo.sh; echo $?
echo '{"tool_input":{"command":"rm  -rf /"}}' | bash security/demo/block-dangerous-demo.sh; echo $?
echo '{"tool_input":{"command":"rm -r -f /"}}' | bash security/demo/block-dangerous-demo.sh; echo $?
echo '{"tool_input":{"command":"rm -fr /"}}' | bash security/demo/block-dangerous-demo.sh; echo $?
echo '{"tool_input":{"command":"drop table users"}}' | bash security/demo/block-dangerous-demo.sh; echo $?
echo '{"tool_input":{"command":"/bin/rm -rf /"}}' | bash security/demo/block-dangerous-demo.sh; echo $?
echo '{"tool_input":{"command":"echo cmQgLXJmIC8= | base64 -d | bash"}}' | bash security/demo/block-dangerous-demo.sh; echo $?
echo '{"tool_input":{"command":"rm -rf /var/www"}}' | bash security/demo/block-dangerous-demo.sh; echo $?
echo '{"tool_input":{"command":"CMD=\"rm -rf /\"; $CMD"}}' | bash security/demo/block-dangerous-demo.sh; echo $?
```

**目的：** 實證字串比對的天花板。
**預期：** 多數穿透。
**實際驗證：** ⚠️ **6 穿透 / 3 被擋（66% 繞過率）**：

| # | 技巧 | 結果 | 原因 |
|---|------|------|------|
| 1 | `RM -RF /` 大寫 | exit 0 ❌ 穿透 | `grep` 預設大小寫敏感，pattern 全小寫 |
| 2 | `rm  -rf /` 雙空格 | exit 0 ❌ 穿透 | `-F` 字面比對，兩格≠一格 |
| 3 | `rm -r -f /` 拆旗標 | exit 0 ❌ 穿透 | `-r -f` ≠ `-rf`，子字串不存在 |
| 4 | `rm -fr /` 順序互換 | exit 0 ❌ 穿透 | `-fr` ≠ `-rf` |
| 5 | `drop table users` 小寫 | exit 0 ❌ 穿透 | pattern 是 `DROP TABLE` 全大寫 |
| 6 | `/bin/rm -rf /` 完整路徑 | exit 2 ✅ 被擋 | `/bin/` 後仍含子字串 `rm -rf /` |
| 7 | base64 混淆 | exit 0 ❌ 穿透 | 危險指令藏在編碼裡，外層字串無 pattern |
| 8 | `rm -rf /var/www` 子目錄 | exit 2 ✅ 被擋（⚠️ 友軍誤傷） | 字串以 `rm -rf /` 為前綴，後面有 `var/www` 也照擋 |
| 9 | `CMD="rm -rf /"; $CMD` 變數 | exit 2 ✅ 被擋 | 引號內字串被整行掃描，字面 pattern 照樣命中 |

**結論：** 字面比對黑名單的根本弱點：

```
破不了的：大小寫 / 空格數量 / 旗標順序 / 小寫 SQL / base64 混淆（6/9 繞過）
意外守住：路徑前綴、引號內字串、子目錄（刪 /var/www 也被擋 = 友軍誤傷）
```

block-dangerous 是「第一道」防線，不是「唯一」防線。更強防禦的梯次：

1. **字串黑名單**（本課）：快、免費，擋 60-70% 笨攻擊
2. **AI 語意裁判**（第 10 課）：懂語意，擋聰明繞過，但每次都花 API 費
3. **Permission Model 白名單**（Part 5）：連 `rm` 本身都不給執行，從根阻斷

---
---

# 第 6 課：mcp-write-guard.sh

> 事件：`PreToolUse`｜ 難度：⭐⭐⭐
> 主題：MCP 後門（Pattern 20）+ 用 JSON 輸出（permissionDecision）取代 exit 2

## 核心觀念

- **MCP 後門**：針對內建工具（Write）的規則，對 MCP 工具（`mcp__filesystem__write`）完全無效 → 正門上鎖、後門大開

- **permissionDecision 三態**：`allow` / `deny` / `ask`（比 exit 2 的二選一細緻；`ask` = 灰色地帶丟回人類）

---

## Step 1：MCP 工具寫 .env — 看 deny JSON

**命令：**

```bash
echo '{"tool_name": "mcp__filesystem__write", "tool_input": {"path": "/app/.env"}}' | bash demo/mcp-write-guard-demo.sh; echo $?
```

**目的：** 看新的攔截方式（JSON 輸出而非 exit 2）。
**預期：** stderr 警告 + stdout 吐 `permissionDecision: deny` JSON。
**實際驗證：** ✅ deny JSON + **exit code = 0（不是 2！）**。

- 反直覺點：明明拒絕，退出碼卻是 0
- 退出碼只說「我正常跑完」，**真正的決定寫在 stdout 的 JSON 裡**
- 這就是為何前幾課一直強調「stdout 保持乾淨、人話走 stderr」→ 此處 stdout 成了 Claude 解析指令的正式通道

---

## Step 2：MCP 工具寫一般檔案 — 確認不誤傷

**命令：**

```bash
echo '{"tool_name": "mcp__filesystem__write", "tool_input": {"path": "/app/src/index.js"}}' | bash demo/mcp-write-guard-demo.sh; echo $?
echo '{"tool_name": "mcp__filesystem__write", "tool_input": {"path": "/app/config.json"}}' | bash demo/mcp-write-guard-demo.sh; echo $?
```

**目的：** 確認只擋敏感檔，一般檔放行。
**預期：** 兩個都 exit 0、stdout 空白。
**實際驗證：** ✅ 都放行。同是 exit 0，但 stdout 空白 = 沒指示 = 放行（對比 Step 1 有 deny JSON）。`config.json` 名字像設定檔但不是 `.env`，守備認**副檔名**（`\.(env|pem|key)$`）不認「感覺危險」。

---

## Step 3：守備範圍總測 — 三敏感副檔名 × 三動詞 + 破口驗證

**命令：** 5 種組合（write/delete/move 敏感檔 + mcp read + 內建 Write）：

```bash
# 三種敏感副檔名 × 三種動詞（2>/dev/null 吞 stderr，只看 stdout）
echo '{"tool_name":"mcp__filesystem__write","tool_input":{"path":"/app/.pem"}}' | bash security/demo/mcp-write-guard-demo.sh 2>/dev/null; echo $?
echo '{"tool_name":"mcp__filesystem__delete","tool_input":{"path":"/app/id_rsa.key"}}' | bash security/demo/mcp-write-guard-demo.sh 2>/dev/null; echo $?
echo '{"tool_name":"mcp__filesystem__move","tool_input":{"path":"/app/.env"}}' | bash security/demo/mcp-write-guard-demo.sh 2>/dev/null; echo $?
# 破口驗證
echo '{"tool_name":"mcp__filesystem__read","tool_input":{"path":"/app/.env"}}' | bash security/demo/mcp-write-guard-demo.sh 2>/dev/null; echo $?
echo '{"tool_name":"Write","tool_input":{"file_path":"/app/.env"}}' | bash security/demo/mcp-write-guard-demo.sh 2>/dev/null; echo $?
```

**目的：** 看清守備邊界與破口。
**預期：** MCP 寫/刪/移敏感檔擋；read 和內建 Write 放行。

⚠️ **jq 換行陷阱**：在 terminal 分兩行貼 `| jq '.field'` 時，第二行被 shell 當成獨立指令 → exit 127。管道後的 jq 必須和前面指令在同一行。

**實際驗證：** ✅ 三個 MCP 寫/刪/移皆回傳 deny JSON（stdout）+ exit 0；**後 2 行暴露破口**：

| 漏網 | 為何放行 | 是漏洞？ |
|------|---------|---------|
| `mcp__filesystem__read` 讀 .env | 清單只有 write/delete/move，沒 read | ⚠️ 是！偷讀外洩一樣致命 |
| 內建 `Write` 寫 .env | 第一關 `mcp__filesystem__` 不匹配 | 🔶 設計如此，破口真實 |

**縱深防禦結論：** 單一 hook 只守一段邊界。要真正保護 .env 還需要：① 把 read 加進清單 ② 另一支守內建 Write/Edit 的 hook。新手安全錯覺：「我擋了 write 就安全」← read 大開、正門大開。

---

## Step 4：解析 deny JSON 結構 + 體會 ask 三態

**命令：**

```bash
# A. 用 jq 拆解 deny JSON（單行，避免換行陷阱）
echo '{"tool_name":"mcp__filesystem__write","tool_input":{"path":"/app/.env"}}' | bash security/demo/mcp-write-guard-demo.sh 2>/dev/null | jq '.hookSpecificOutput'
# B. ask 版（守備 .sql 遷移腳本）
echo '{"tool_name":"mcp__filesystem__write","tool_input":{"path":"/db/migration.sql"}}' | bash security/demo/mcp-ask-demo.sh 2>/dev/null
```

**目的：** 拆解 deny JSON 逐欄解釋，示範改成 `ask` 的灰色地帶情境。
**預期：** A 印出三欄位；B 吐出 `permissionDecision: ask` 的 JSON。
**實際驗證：** ✅ 兩部分都到位（A：jq 以單行跑出三欄位；B：mcp-ask-demo.sh 確認存在且回傳 ask JSON）。

**A. deny JSON 三欄位：**

| 欄位 | 值 | 作用 |
|------|----|----|
| `hookEventName` | PreToolUse | 回應要對得上事件名 |
| `permissionDecision` | deny | 核心決定（allow/deny/ask）|
| `permissionDecisionReason` | 不允許存取敏感檔案 | 理由，回傳 Claude / 顯示人類 |

（暗坑：不同事件支援的 JSON 欄位不同 — 第 8 課 audit-config 用的是 `{decision, reason}` 格式，寫前要查表）

**B. ask 三態完整光譜：**

| 決定 | 行為 | 適用 |
|------|------|------|
| `deny` | 直接拒絕 | 100% 該擋（敏感檔）|
| `allow` | 放行（跳過權限提示）| 100% 信任 |
| `ask` | **暫停問人類** | 灰色地帶（.sql 遷移 / git reset）|

`.sql` 遷移腳本「有時該執行、有時很危險」，Bash 看不懂語意 → 與其武斷全擋/全放，不如把決策權丟回有上下文的人類（字稿讚賞的「全自動化與人工審核之間的動態平衡點」）。

**三段式風險分級（完整）：** 無害→放行(allow/不輸出)；災難→擋死(deny/exit 2)；灰色→問人(ask)。

**新增產出物：** `mcp-ask-demo.sh`（ask 版變體）

---

**產出物：** `block-dangerous-demo.sh`、`mcp-write-guard-demo.sh`
