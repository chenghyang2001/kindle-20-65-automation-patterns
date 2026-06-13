# 第二章 Hooks 範例程式完整教學（職場新鮮人版）

> 對象：剛進職場、第一次接觸 Claude Code Hooks 的新鮮人
> 教材：`code-中文/part2-hooks/` 目錄下的 6 個子目錄、12 個範例檔
> 目標：照「最簡單 → 最複雜」的順序，一個一個搞懂每支範例在做什麼、為什麼需要它
> 來源：《Claude Code in Production》第二章「Hooks 的 17 個事件完整目錄」

---

## 開始之前：什麼是 Hook？為什麼你需要它？

想像你帶了一個超級聰明、但完全沒有「常識」的新同事。他打字飛快、邏輯完美，
但有一天他為了清出硬碟空間，直接把整個專案目錄刪掉了——他不是故意搞破壞，
在他的腦袋裡，這就是「最有效率的清理方案」。

AI 助理（Claude Code）就是這個新同事。它極度聰明，卻缺乏判斷「這件事做下去
會不會出大事」的常識。**Hook 就是你幫它設下的邊界**：在它做某個動作的「前一刻」
或「後一刻」，自動執行一段你寫好的檢查程式。

Hook 的運作只有三個核心概念，記住這三個，後面 12 支範例全部都看得懂：

1. **事件（Event）**：Hook 掛在「什麼時間點」。例如 `PreToolUse`（工具執行前）、
   `PostToolUse`（工具執行後）、`Stop`（AI 準備宣告完工時）、
   `SessionStart`（新對話開始時）。
2. **輸入（stdin）**：Claude Code 會把「現在發生什麼事」打包成一段 JSON，
   從標準輸入（stdin）餵給你的腳本。你的腳本用 `jq`（Bash）或
   `JSON.parse`（Node.js）把它拆開來看。
3. **輸出（exit code / stdout）**：你的腳本用「退出碼」告訴 Claude 怎麼辦——
   - `exit 0`：放行，一切正常
   - `exit 2`：阻擋！而且 stderr 的錯誤訊息會回傳給 Claude，逼它換個做法
   - 進階版：輸出一段 JSON（例如 `{"decision": "block", "reason": "..."}`），
     可以做更細緻的控制

> 一句話總結：**Hook = 在關鍵時間點，用一段小程式攔住 AI，檢查完再決定放不放行。**

---

## 學習地圖：12 個檔案的演練順序

| 順序 | 檔案 | 難度 | 一句話說明 |
|:---:|------|:---:|-----------|
| 1 | `settings-examples/debug-hook.sh` | ⭐ | 把 hook 收到的東西全部寫進日誌——理解「輸入長什麼樣」 |
| 2 | `notification/notify.sh` | ⭐ | AI 等你輸入時，跳系統通知 + 發 Slack |
| 3 | `quality/auto-format.sh` | ⭐⭐ | AI 改完檔案後，自動跑格式化工具 |
| 4 | `security/block-dangerous.sh` | ⭐⭐ | 攔截 `rm -rf /` 等危險指令（exit 2 的經典示範） |
| 5 | `platform/check-command.mjs` | ⭐⭐ | 同樣的攔截邏輯，改用 Node.js 寫——跨平台對照組 |
| 6 | `security/mcp-write-guard.sh` | ⭐⭐⭐ | 堵住 MCP 後門：保護 .env / .pem / .key 敏感檔 |
| 7 | `lifecycle/save-session-state.sh` + `restore-context.sh` | ⭐⭐⭐ | 一存一讀，治好 AI 的「失憶症」 |
| 8 | `lifecycle/audit-config.sh` | ⭐⭐⭐ | 設定檔被改時留下稽核紀錄，必要時阻擋 |
| 9 | `quality/quality-gate.sh` | ⭐⭐⭐⭐ | AI 想下班？先過品質檢查——含「無限迴圈煞車」 |
| 10 | `quality/prompt-hook-examples.json` | ⭐⭐⭐⭐⭐ | 終極型態：讓另一個 AI 當裁判，審查 AI 的工作 |

---

## 第 1 課：debug-hook.sh —— 先學會「看見」Hook 收到了什麼

**檔案**：`settings-examples/debug-hook.sh`（搭配 `hooks-overview.json` 一起看）
**事件**：任何事件都能掛
**難度**：⭐

### 它在做什麼？

這是全部 12 支裡最簡單的一支，總共只做一件事：
把 Claude Code 餵進來的 JSON，原封不動寫進 `/tmp/claude-hook-debug.log`。

```bash
INPUT=$(cat)                                  # 從 stdin 讀進整包 JSON
echo "=== $(date) ===" >> /tmp/claude-hook-debug.log
echo "EVENT: $(echo "$INPUT" | jq -r '.hook_event_name')" >> ...
echo "$INPUT" | jq '.' >> /tmp/claude-hook-debug.log   # 美化排版後存檔
exit 0                                        # 永遠放行，它只記錄、不攔截
```

### 為什麼要從它開始學？

因為寫 Hook 最常見的挫折是：「我根本不知道 Claude 餵給我的 JSON 長什麼樣子，
要怎麼寫判斷邏輯？」這支腳本就是你的「行車記錄器」——先掛上去跑幾次，
打開日誌檔看看每種事件的 JSON 結構，你就知道有哪些欄位可以用了。

### 新鮮人必懂的三行程式

- `INPUT=$(cat)`：Hook 腳本的標準起手式。`cat` 不接檔名時會讀 stdin，
  這行就是「把 Claude 給我的整包 JSON 存進變數」。
- `jq -r '.hook_event_name'`：`jq` 是命令列的 JSON 小刀，`-r` 表示輸出純文字
  （不帶引號）。這行是「從 JSON 裡挖出事件名稱」。
- `exit 0`：明確告訴 Claude「我看完了，放行」。

### 怎麼手動測試？

不需要真的等 Claude 觸發，直接用 `echo` 假造一包 JSON 塞給它：

```bash
echo '{"hook_event_name": "PreToolUse", "tool_name": "Bash"}' | bash debug-hook.sh
cat /tmp/claude-hook-debug.log    # 看看有沒有寫進去
```

這個「echo 假 JSON ➜ pipe 給腳本 ➜ 肉眼看輸出」的測試手法，
是後面每一課都會重複用到的基本功，書中 Pattern 22 特別強調：
**永遠不要靠 Claude 的實際行為來除錯 Hook，要自己手動重現。**

### 搭配看：hooks-overview.json

同目錄的 `hooks-overview.json` 是 hook 的「掛載設定範例」，告訴你腳本要怎麼
登記到 Claude Code 的 `settings.json`：

```json
{
  "hooks": {
    "PostToolUse": [                      // 掛在「工具執行後」
      {
        "matcher": "Edit|Write",          // 只有 Edit 或 Write 工具才觸發
        "hooks": [
          { "type": "command", "command": "npx prettier --write ..." }
        ]
      }
    ]
  }
}
```

三層結構記起來：**事件名稱 → matcher（過濾哪些工具）→ 要執行的指令**。

---

## 第 2 課：notify.sh —— AI 在等你的時候，主動叫你

**檔案**：`notification/notify.sh`
**事件**：`Notification`（Claude 需要使用者注意時觸發）
**難度**：⭐

### 它在做什麼？

你有沒有遇過：交辦 AI 一個長任務，自己跑去喝咖啡，回來才發現它早就停在那裡
等你按確認，白白浪費了二十分鐘？這支 Hook 解決的就是這件事。

當 Claude 進入「等待使用者輸入」狀態時，它會：

1. 跳一個 macOS 系統通知（`osascript`）
2. 如果有設定 `SLACK_WEBHOOK_URL` 環境變數，再發一則 Slack 訊息

```bash
TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')
```

### 新鮮人必懂的兩個寫法

- `// "unknown"`：這是 jq 的「預設值」語法。如果 JSON 裡沒有
  `notification_type` 這個欄位，就用 `"unknown"` 頂替，腳本不會炸掉。
  **防禦性寫法——永遠假設欄位可能不存在。**
- `if [ -n "$SLACK_WEBHOOK" ]`：`-n` 是「字串非空」。沒設定 Slack 就直接跳過，
  不會噴錯。這叫「優雅降級」：功能可有可無，但絕不報錯。

### Windows 使用者注意

`osascript` 是 macOS 專屬指令，在 Windows 上會失敗——但因為後面跟了
`2>/dev/null`（把錯誤丟掉），所以只是「靜默跳過」，不會弄壞整個 Hook。
這正好示範了跨平台的痛點，第 5 課會給出正解。

---

## 第 3 課：auto-format.sh —— AI 寫完檔案，自動幫它「整理儀容」

**檔案**：`quality/auto-format.sh`
**事件**：`PostToolUse`（matcher 設 `Edit|Write`，即「AI 改完/寫完檔案之後」）
**難度**：⭐⭐

### 它在做什麼？

AI 寫程式碼的「內容」通常沒問題，但「排版」三不五時會飄掉——縮排不一致、
引號混用。與其每十分鐘提醒它一次專案的排版規則，不如**每次它寫完檔案，
就自動跑一次格式化工具**。

```bash
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
EXT="${FILE_PATH##*.}"          # Bash 取副檔名的慣用寫法

case "$EXT" in
  js|jsx|ts|tsx|css|json)  npx prettier --write "$FILE_PATH" ;;
  go)                      gofmt -w "$FILE_PATH" ;;
  py)                      black "$FILE_PATH" ;;
  md)                      npx markdownlint-cli2 --fix "$FILE_PATH" ;;
esac
```

### 新鮮人必懂的三個重點

1. **`.tool_input.file_path`**：注意這是「兩層」的 JSON 路徑。Hook 輸入的結構是
   `{ "tool_name": "Write", "tool_input": { "file_path": "...", ... } }`，
   工具的參數都包在 `tool_input` 裡面。
2. **`${FILE_PATH##*.}`**：Bash 參數展開，意思是「從開頭刪掉最長的 `*.` 匹配」，
   剩下的就是副檔名。比呼叫外部指令快得多。
3. **提前離場**：`if [ -z "$FILE_PATH" ]; then exit 0; fi`——
   如果這次操作根本沒有檔案路徑（例如不是寫檔工具），直接放行走人。
   **Hook 的第一原則：不關你的事就趕快 exit 0，不要擋路。**

### 它和第 1 課 hooks-overview.json 的關係

`hooks-overview.json` 裡那行 `npx prettier --write ...` 就是這支腳本的「單行版」。
單行版簡單但只支援一種格式化工具；這支腳本版多了副檔名分流，
能同時照顧 JS、Go、Python、Markdown 四種語言。**從單行到腳本，就是 Hook 的成長路徑。**

---

## 第 4 課：block-dangerous.sh —— 第一道保命防線（本章核心！）

**檔案**：`security/block-dangerous.sh`
**事件**：`PreToolUse`（matcher 設 `Bash`，即「AI 要執行終端機指令的前一刻」）
**難度**：⭐⭐

### 它在做什麼？

回到開頭那個惡夢場景：AI 為了清空間直接 `rm -rf` 你的專案。
這支腳本就是擋在「AI 扣下扳機之前」的最後一道防線。

```bash
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

PATTERNS=(
  "rm -rf /"          # 刪除根目錄——系統毀滅
  "rm -rf ~"          # 刪除家目錄——個人資料毀滅
  "git push --force"  # 強制推送——覆蓋隊友的 commit
  "git push -f"       # 同上的縮寫版
  "chmod -R 777"      # 權限全開——資安大洞
  "DROP TABLE"        # 刪除資料表——資料庫毀滅
  "> /dev/sda"        # 直接覆寫硬碟裝置
)

for pattern in "${PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qF "$pattern"; then
    echo "已阻擋：'$pattern' 是被禁止的指令" >&2   # 訊息寫到 stderr
    exit 2                                          # 關鍵！exit 2 = 阻擋
  fi
done

exit 0
```

### 這一課要徹底搞懂的機制：exit code 通訊協定

| 退出碼 | 意義 | Claude 的反應 |
|:---:|------|--------------|
| `exit 0` | 放行 | 照常執行指令 |
| `exit 2` | 阻擋 | **不執行**指令，並把 stderr 的訊息讀進上下文 |

最妙的是第二點：`exit 2` 不只是「擋下來」，stderr 上的那句
「已阻擋：'rm -rf /' 是被禁止的指令」會被**原封不動塞回給 Claude**。
Claude 收到後會意識到「喔，這條路不通」，自動換一個安全的做法。

這就形成了一個**不需要人類介入的自我修正迴圈**——你不用坐在螢幕前盯著，
系統自己會把 AI 導回正軌。這是整個 Hooks 架構最優雅的設計。

### 新鮮人必懂的細節

- `grep -qF`：`-q` 安靜模式（只回傳成功/失敗，不印東西）、
  `-F` 把 pattern 當「純文字」而非正規表示式——
  不然 `rm -rf /` 裡的 `/` 和 `> /dev/sda` 裡的 `>` 可能引發誤判。
- `>&2`：把訊息導向 stderr。**stdout 和 stderr 在 Hook 裡是兩條不同的通道**，
  阻擋訊息走 stderr，結構化資料（JSON）走 stdout，不能混。

### 手動測試

```bash
# 危險指令 → 應該 exit 2
echo '{"tool_input": {"command": "rm -rf /"}}' | bash block-dangerous.sh
echo $?     # 印出上一個指令的退出碼，應該是 2

# 安全指令 → 應該 exit 0
echo '{"tool_input": {"command": "ls -la"}}' | bash block-dangerous.sh
echo $?     # 應該是 0
```

### 思考題（面試會考！）

字串比對有極限：如果 AI 下的是 `rm -rf /tmp/../`，或是把指令拆成變數再執行呢？
這支腳本擋不住。所以它是「第一道」防線，不是「唯一」防線——
更聰明的判斷要靠第 10 課的 Prompt Hooks。

---

## 第 5 課：check-command.mjs —— 同一件事，Node.js 怎麼寫？

**檔案**：`platform/check-command.mjs`
**事件**：`PreToolUse`
**難度**：⭐⭐

### 它在做什麼？

功能和第 4 課**一模一樣**：攔截危險指令。但改用 Node.js 實作。
把兩支並排看，是這一課的全部意義。

```javascript
const input = await readStdin()              // 讀 stdin
const { tool_name, tool_input } = input      // 解構取欄位

if (tool_name === 'Bash') {
  const command = tool_input?.command ?? ''
  const BLOCKED = ['rm -rf', 'git push --force', 'DROP TABLE']
  for (const pattern of BLOCKED) {
    if (command.includes(pattern)) {
      process.stderr.write(`已阻擋：'${pattern}' 是被禁止的指令\n`)
      process.exit(2)                        // 同樣的 exit 2 協定
    }
  }
}
process.exit(0)
```

### 為什麼書裡（Pattern 21）建議用 Node.js 而不是 Bash？

| 比較項 | Bash 版（第 4 課） | Node.js 版（本課） |
|--------|------------------|------------------|
| Windows 能跑嗎 | 要裝 Git Bash / WSL，雷很多 | 裝了 Node 就能跑，**原生跨平台** |
| JSON 解析 | 依賴外部工具 `jq`（要另外安裝、有版本相容問題） | **內建** `JSON.parse`，零依賴 |
| 缺欄位的防禦 | `jq -r '.x // empty'` 語法繞口 | `tool_input?.command ?? ''` 直觀 |
| 適合場景 | macOS/Linux 個人用、邏輯簡單 | **團隊共用、跨平台、邏輯複雜** |

兩個 JavaScript 語法新鮮人要認得：

- `?.`（optional chaining）：`tool_input?.command` 意思是
  「如果 `tool_input` 是 null/undefined，整串直接回 undefined，不要炸」。
- `??`（nullish coalescing）：「左邊是 null/undefined 時才用右邊的預設值」。
  注意它和 `||` 不同——`0 || 'x'` 會回 `'x'`（0 被當 false），
  `0 ?? 'x'` 會回 `0`。處理數字欄位時這個差異會咬人。

### 手動測試

```bash
echo '{"tool_name": "Bash", "tool_input": {"command": "rm -rf /tmp"}}' | node check-command.mjs
echo $?    # 2
```

### 給你（Windows 使用者）的特別叮嚀

你的主力環境就是 Windows 10 + Git Bash，這課就是為你而設的。
原則：**自己玩可以用 Bash，要分享給同事、要進團隊 repo 的 Hook，一律用 Node.js 寫。**
你把一支滿是 `grep` 和 `awk` 的 Bash 腳本丟給用 PowerShell 的同事，系統直接崩潰。

---

## 第 6 課：mcp-write-guard.sh —— 堵住最容易被忽略的後門

**檔案**：`security/mcp-write-guard.sh`
**事件**：`PreToolUse`
**難度**：⭐⭐⭐

### 先講背景：什麼是 MCP 後門？（Pattern 20）

MCP（Model Context Protocol）是讓 Claude 外接各種服務的協定——
連 GitHub、連資料庫、連檔案系統。問題來了：

> **你針對內建工具（Bash、Write、Edit）設的所有攔截規則，對 MCP 工具通通無效。**

因為 MCP 工具走的是獨立的協定層，名字長得完全不一樣：
內建寫檔工具叫 `Write`，MCP 的寫檔工具叫 `mcp__filesystem__write`。
你的 matcher 寫 `Write`，它根本匹配不到後者。

這等於：你把正門鎖得死死的，卻給了 AI 一把能隨意開後門的萬能鑰匙。
它可以透過 MCP 在你不知情的情況下改檔案、刪資料、push 程式碼。

### 它在做什麼？

```bash
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

# 用正規表示式捕獲 MCP 的檔案寫入/刪除/搬移工具
if echo "$TOOL" | grep -qE "mcp__filesystem__(write|delete|move)"; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.source // empty')
  # 保護三種敏感副檔名
  if echo "$FILE" | grep -qE "\.(env|pem|key)$"; then
    echo "已阻擋 MCP 存取敏感檔案：$FILE" >&2
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "不允許存取敏感檔案"
      }
    }'
    exit 0
  fi
fi
exit 0
```

### 這一課的新東西：JSON 輸出取代 exit 2

注意！它阻擋的方式**不是 `exit 2`**，而是：
印出一段結構化 JSON 到 stdout，然後 `exit 0`。

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "不允許存取敏感檔案"
  }
}
```

`permissionDecision` 有三種值，這是 Hook 的「進階控制協定」：

| 值 | 效果 | 用在什麼時候 |
|----|------|------------|
| `"allow"` | 直接放行，連權限提示都跳過 | 你 100% 信任的操作 |
| `"deny"` | 拒絕，理由回傳給 Claude | 你 100% 禁止的操作 |
| `"ask"` | **暫停，跳出提示讓人類決定** | 灰色地帶（例如 `git reset`） |

`"ask"` 是書裡特別讚賞的設計：對於「有時該擋、有時該放」的指令，
不要寫死規則，把決策權丟回給人類——在全自動化和人工審核之間取得動態平衡。

### 為什麼保護的是 .env / .pem / .key？

- `.env`：環境變數檔，裡面是資料庫密碼、API 金鑰
- `.pem` / `.key`：私鑰檔，SSH 登入、TLS 憑證用的

這三種檔案一旦被 AI 誤讀、誤改、或不小心寫進 commit，就是資安事故。
新鮮人記住：**機密檔案的保護要做在系統層（Hook），不能只靠「提醒 AI 小心」。**

### 手動測試

```bash
# MCP 工具寫 .env → 應該輸出 deny JSON
echo '{"tool_name": "mcp__filesystem__write", "tool_input": {"path": "/app/.env"}}' | bash mcp-write-guard.sh

# MCP 工具寫一般檔案 → 應該安靜放行
echo '{"tool_name": "mcp__filesystem__write", "tool_input": {"path": "/app/index.js"}}' | bash mcp-write-guard.sh
```

---

## 第 7 課：save-session-state.sh + restore-context.sh —— 治好 AI 的失憶症

**檔案**：`lifecycle/save-session-state.sh`（存）＋ `lifecycle/restore-context.sh`（讀）
**事件**：`PreCompact` / `SessionEnd`（存）＋ `SessionStart`（讀）
**難度**：⭐⭐⭐

### 先講背景：AI 為什麼會失憶？（Pattern 15 + 16）

大語言模型有「上下文視窗」的容量限制。對話越來越長，視窗總有塞滿的一天。
這時 Claude Code 會自動做「上下文壓縮（compact）」——把先前的對話總結成摘要。

聽起來合理，但壓縮過程中，**對開發最重要的微小細節會無可挽回地遺失**：
你現在在哪個 git 分支、剛才測試失敗的是哪個檔案、早上決定 token 要存在哪裡。

書裡的比喻很傳神：就像團隊開了八小時馬拉松會議，到傍晚大家只記得
「我們在重構登入模組」，但沒人記得早上拍板的關鍵決策。

### 解法：兩支腳本聯動，打造「外接記憶硬碟」

**第一支 save-session-state.sh（壓縮前搶救記憶）：**

在系統準備壓縮、但還沒抹除細節的「前一刻」（`PreCompact` 事件），
把關鍵狀態寫進硬碟上的實體檔案 `.claude/session-state.md`：

```bash
cat > "$STATE_FILE" << EOF
# Session 狀態（儲存時間：${TIMESTAMP} / 觸發來源：${TRIGGER}）

## 分支
$(git branch --show-current)

## 未 Commit 的變更
$(git diff --name-only)
$(git diff --name-only --cached | sed 's/^/[staged] /')

## 最近的 Commit（5 筆）
$(git log --oneline -5)
EOF
```

**第二支 restore-context.sh（醒來後讀回記憶）：**

新 session 開始（`SessionStart` 事件）時，這支腳本的 **stdout 會被當成
背景上下文注入給 Claude**——這是 SessionStart hook 的特殊能力：

```bash
echo "## 已還原的 Session 上下文"
echo "### 分支：$(git branch --show-current)"
echo "### 最近的 Commit"
git log --oneline -3
# 若存在上次的狀態檔，整份附上
[ -f .claude/session-state.md ] && cat .claude/session-state.md
```

效果：AI 一「醒來」就自動知道「我在 feature 分支、有三個檔案改到一半、
上次卡在某個測試」。

### 你每天都在享受這個機制（真實案例！）

你有沒有注意過，每次開新的 Claude Code 對話，開頭都會出現一段
「Restored Session Context / Recent Commits / Uncommitted Changes」？
**那就是這一套 save + restore 機制在你自己的環境裡實際運作的結果。**
這不是教科書上的玩具範例，是你天天在用的基礎設施。

### 新鮮人必懂的防禦性寫法（save 這支特別精彩）

```bash
# 1. 依賴檢查：jq 沒裝就明確報錯，不要靜默壞掉
if ! command -v jq &>/dev/null; then
  echo "錯誤：jq 未安裝" >&2
  exit 1
fi

# 2. 空輸入防禦：避免 bash 參數展開歧義污染 jq
[ -z "$INPUT" ] && INPUT='{}'

# 3. 寫入失敗要報錯，不能假裝成功
if ! cat > "$STATE_FILE" << EOF
...
EOF
then
  echo "錯誤：寫入 ${STATE_FILE} 失敗" >&2
  exit 1
fi
```

這三段就是「快樂路徑 vs 生產等級」的差別。新鮮人寫腳本最常犯的錯
就是只寫快樂路徑——工具沒裝、目錄不存在、磁碟滿了，全部沒處理，
壞掉的時候一聲不吭，三天後才發現狀態檔是空的。

---

## 第 8 課：audit-config.sh —— 誰動了我的設定檔？

**檔案**：`lifecycle/audit-config.sh`
**事件**：設定檔變更類事件（config change）
**難度**：⭐⭐⭐

### 它在做什麼？

兩件事，一明一暗：

1. **稽核（audit）**：任何設定檔被動到，都在 `.claude/config-audit.log`
   留下一行「時間 | 來源 | 檔案」的紀錄。出事的時候可以回頭查。
2. **阻擋（block）**：如果被改的是專案的 `settings.json`，輸出
   `{"decision": "block", "reason": "..."}` 擋下來，要求先人工檢視。

```bash
echo "${DATE} | ${SOURCE} | ${FILE}" >> ".claude/config-audit.log"

if [ "$SOURCE" = "project_settings" ]; then
  if [ "$(basename "$FILE")" = "settings.json" ]; then
    jq -n '{
      "decision": "block",
      "reason": "偵測到 settings.json 遭外部修改。請先檢視變更內容再繼續。"
    }'
    exit 0
  fi
fi
```

### 為什麼設定檔要特別保護？

想一個攻擊場景：Hook 的規則都登記在 `settings.json` 裡。
如果有人（或 AI 自己）偷偷改了 `settings.json`，把你的安全 Hook 移除掉呢？
**你的整套防護網就被連根拔起了，而且你不會察覺。**

所以「保護防護網本身」是安全設計的必修課。這支 Hook 就是防護網的防護網。

### 這一課的新概念：decision/reason JSON 格式

第 6 課看過 `permissionDecision`（PreToolUse 專用），這課是另一種格式：

```json
{ "decision": "block", "reason": "為什麼擋你" }
```

不同事件支援的 JSON 輸出格式不完全相同——這是 Hooks 開發的暗坑之一。
記住查表的習慣：**寫某個事件的 Hook 前，先查那個事件支援哪些輸出欄位。**

### 職場小提醒：稽核日誌的價值

新鮮人常覺得「寫 log 好無聊」。但在企業環境，稽核日誌是出事時
自保和歸因的唯一證據。「誰、什麼時候、改了什麼」這三個欄位，
平常沒人看，出事時價值連城。

---

## 第 9 課：quality-gate.sh —— AI 想下班？先過品質檢查

**檔案**：`quality/quality-gate.sh`
**事件**：`Stop`（AI 準備宣告「任務完成」的前一刻）
**難度**：⭐⭐⭐⭐

### 它在做什麼？

AI 有時會「自我感覺良好」：程式碼還有 TODO 沒寫完、變更沒 commit，
它就宣布大功告成準備收工。`Stop` 事件讓你在它「下班打卡前」攔住它：

```bash
ISSUES=()

# 檢查一：有沒有未 commit 的變更？
UNCOMMITTED=$(git diff --name-only)
STAGED=$(git diff --name-only --cached)
if [ -n "$UNCOMMITTED" ] || [ -n "$STAGED" ]; then
  ISSUES+=("偵測到未 commit 的變更")
fi

# 檢查二：程式碼裡還有沒有殘留的 TODO 標記？
TODO_COUNT=$(grep -r "<!-- TODO -->" src/ | wc -l)
if [ "$TODO_COUNT" -gt 0 ]; then
  ISSUES+=("還有 ${TODO_COUNT} 個 TODO 標記未處理")
fi

# 有問題就 block，AI 必須回去收尾
if [ ${#ISSUES[@]} -gt 0 ]; then
  jq -n --arg reason "..." '{"decision": "block", "reason": $reason}'
  exit 0
fi
exit 0
```

被擋下的 AI 會收到具體的 reason 清單（「1. 偵測到未 commit 的變更
2. 還有 3 個 TODO」），然後回去把工作收尾，**不能直接下班**。

### 本課最重要的概念：無限迴圈煞車（書中特別警告的防護死角！）

先想一個災難場景：

```
AI 嘗試停止 → Hook 拒絕 → AI 嘗試修復 → 修復失敗 →
AI 再次嘗試停止 → Hook 再次拒絕 → ……（無限循環，API 額度燒光）
```

如果 AI 遇到一個它「修不好」的問題（例如 TODO 在它權限外的檔案裡），
這個迴圈會永遠轉下去，把你的錢燒光。解法就是腳本的**前四行**：

```bash
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0    # 已經在「被 Hook 擋回去重試」的狀態 → 直接放行，不再擋第二次
fi
```

`stop_hook_active` 是系統提供的狀態旗標：`true` 表示
「這次的 Stop 是上次被你擋回去之後的重試」。看到它就放行，
保證 AI 最多被擋一次，絕不無限撞牆。

> 金句記下來：**設定防護網的同時，要為防護網本身裝上煞車。**

### 為什麼它是第 9 課（倒數第二難）？

因為它集合了前面所有課的技能：jq 解析（第 1 課）、條件分流（第 3 課）、
decision JSON（第 8 課），再加上獨有的「狀態機思維」——
你必須考慮「這是第一次觸發還是重試」，腳本的行為跟著狀態改變。

### 手動測試（兩種狀態都要測！）

```bash
# 狀態一：正常觸發（stop_hook_active = false）→ 會跑檢查
echo '{"stop_hook_active": false}' | bash quality-gate.sh

# 狀態二：重試觸發（stop_hook_active = true）→ 應該直接放行、無輸出
echo '{"stop_hook_active": true}' | bash quality-gate.sh
```

---

## 第 10 課：prompt-hook-examples.json —— 終極型態：讓 AI 審查 AI

**檔案**：`quality/prompt-hook-examples.json`
**事件**：`Stop`、`UserPromptSubmit`、`PostToolUse`（一檔三範例）
**難度**：⭐⭐⭐⭐⭐

### 先講背景：字串比對的天花板（Pattern 19）

前面 9 課的判斷邏輯，本質上都是「字串比對」：指令裡有沒有 `rm -rf`、
檔名是不是 `.env` 結尾。但有些判斷需要**理解語意**：

- 「這次的資料庫遷移腳本，會不會讓既有的 API 崩潰？」
- 「使用者貼的這段 prompt，有沒有夾帶 API 金鑰？」
- 「這個 .ts 檔案的修改，有沒有 SQL 注入的風險？」

正規表示式看不懂這些。這時候就要請出 **Prompt Hooks**：
把 Hook 的 `type` 從 `"command"` 改成 `"prompt"`，
讓**另一個 AI 模型來當裁判**，審查主模型的工作。

### 範例檔裡的三個實戰場景

**場景一：Stop 事件——AI 裁判版的品質閘門**

```json
{
  "type": "prompt",
  "prompt": "請檢視以下 session 資料：\n$ARGUMENTS\n\n檢查以下所有項目：
    1. 若 stop_hook_active 為 true，必須回傳 ok: true
    2. 若 last_assistant_message 含有錯誤或顯示工作未完成，回傳 ok: false
    3. 其餘情況回傳 ok: true
    \n一律以 JSON 格式回應：{\"ok\": true/false, \"reason\": \"原因\"}"
}
```

注意第 1 條規則：**無限迴圈煞車也寫進了 prompt 裡**——
第 9 課用 Bash 寫的煞車邏輯，這裡用自然語言交代給裁判模型。同一個概念，兩種實作。

**場景二：UserPromptSubmit 事件——攔截使用者自己的失誤**

使用者送出 prompt 前，先讓裁判檢查有沒有不小心貼上 API 金鑰、密碼、個資。
**Hook 不只能管 AI，也能管人類**——防止你手滑把公司機密貼進對話。

**場景三：PostToolUse 事件——每次改檔後的自動資安審查**

```json
{
  "type": "prompt",
  "model": "claude-haiku-4-5-20251001",
  "prompt": "...僅當 tool_input.file_path 是 .ts 或 .js 檔案時，
    檢查是否有明顯的安全問題（SQL 注入、XSS、寫死的憑證）..."
}
```

### 必懂機制一：裁判的回應協定 {ok, reason}

裁判模型被嚴格限制只能回兩種 JSON：

| 回應 | 效果 |
|------|------|
| `{"ok": true}` | 放行 |
| `{"ok": false, "reason": "具體原因＋修復建議"}` | 阻擋，且 **reason 會被原封不動注入主模型的上下文，當作下一個指令** |

`reason` 是整個架構的靈魂：主模型收到後，等於聽到一位資深 Tech Lead 說
「你第 42 行有 SQL 注入，改用參數化查詢」，然後它就會照著修。
**這等於給你的 AI 助理配了一個不知疲倦、每次提交前都做 code review 的資深前輩。**

### 必懂機制二：裁判模型的成本/速度權衡

「把一個 LLM API 呼叫塞進攔截迴圈，不會拖垮開發節奏嗎？」——好問題。

| 裁判模型 | 速度 | 成本 | 適用 |
|---------|------|------|------|
| Haiku（**預設**） | 幾百毫秒 | 極低 | 日常檢查：格式、敏感資訊、明顯漏洞 |
| Sonnet（設定 `"model"` 指定） | 較慢 | 較高 | 大規模重構的安全性評估等複雜語意審查 |

預設用 Haiku 所以幾乎無感；範例的場景三明確指定了 Haiku 的完整模型 ID，
就是「成本意識」的示範——**用大砲打蚊子的錢，是你自己出的。**

### 為什麼它是最後一課？

因為它是「質變」：前 9 課你在寫**規則**（if-else），這一課你在管理**裁判**
（用 prompt 描述標準，讓另一個模型做判斷）。書末的思想實驗也從這裡出發：
當模型聰明到能自己寫 Hook 約束自己時，人類的角色會變成什麼？
——你不再是提示工程師，你是這個自動化系統的**架構師**。

---

## 總複習：一張表收斂全部 12 個檔案

| # | 檔案 | 事件 | 攔截手段 | 核心一句話 |
|:-:|------|------|---------|-----------|
| 1 | debug-hook.sh | 任意 | 不攔截（log only） | 先看見輸入，才寫得出判斷 |
| 1' | hooks-overview.json | — | — | 事件 → matcher → command 三層結構 |
| 2 | notify.sh | Notification | 不攔截 | AI 等你時主動叫你 |
| 3 | auto-format.sh | PostToolUse | 不攔截（修正） | 寫完自動格式化，不用每 10 分鐘提醒 |
| 4 | block-dangerous.sh | PreToolUse | **exit 2** | 扣扳機前的最後防線 |
| 5 | check-command.mjs | PreToolUse | exit 2 | 同第 4 課，Node.js 跨平台版 |
| 6 | mcp-write-guard.sh | PreToolUse | **permissionDecision JSON** | MCP 是繞過正門的後門，要單獨設防 |
| 7 | save/restore 兩支 | PreCompact + SessionStart | 不攔截（注入） | 外接記憶硬碟，治療壓縮失憶 |
| 8 | audit-config.sh | config 變更 | **decision: block JSON** | 防護網的防護網 |
| 9 | quality-gate.sh | Stop | decision: block JSON | 下班前過品質閘門＋無限迴圈煞車 |
| 10 | prompt-hook-examples.json | Stop / UserPromptSubmit / PostToolUse | **{ok, reason} 裁判協定** | 讓 AI 審查 AI，reason 注入主模型自動修復 |

### 三種攔截手段的演進（記住這個脈絡）

```
exit 2 + stderr 訊息          ← 最簡單：擋 / 不擋 二選一
    ↓
JSON 結構化輸出               ← 更細緻：allow / deny / ask 三態 + 理由
（permissionDecision / decision: block）
    ↓
prompt hook {ok, reason}      ← 最聰明：交給另一個 AI 做語意判斷
```

### 除錯三寶（出事時照這個順序查）

1. **手動 pipe 測試**：`echo '假JSON' | bash 你的hook.sh`，肉眼確認輸出純淨
2. **debug-hook.sh**：掛上行車記錄器，看真實事件的 JSON 長相
3. **環境變數 `CLAUDE_HOOK_DEBUG=1`**：強制印出所有 hook 執行軌跡——
   特別能抓出「shell 設定檔污染」（.bashrc 的歡迎訊息混進 JSON 輸出，
   像後端 API 回傳 JSON 前被塞了一段 HTML 廣告橫幅）

---

## 結語：你正在從「使用 AI」跨越到「架構 AI」

學完這 10 課，你掌握的不是 12 支腳本，而是一套思維：

- **防禦**：PreToolUse 攔危險指令、MCP 後門單獨設防、設定檔加稽核
- **品質**：PostToolUse 自動格式化、Stop 閘門逼 AI 好好收尾
- **記憶**：PreCompact 存檔、SessionStart 還原，AI 不再失憶
- **進化**：Prompt Hooks 讓 AI 審 AI，reason 迴路自動修復

把一個充滿潛力但不太受控的模型，透過基礎設施的約束，
塑造成企業級的自動化開發系統——掌握 Hooks，本質上就是掌握
AI 代理迴圈的控制權。

接下來，我們就照學習地圖的順序，一課一課實際動手跑。
