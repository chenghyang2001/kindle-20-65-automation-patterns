# 第 6 課演練記錄：Hook 攔截器（Pre-Tool-Use Hooks）

> 對應文件：
>
> - `code-中文/part5-security/hooks/secret-scanner.sh`
> - `code-中文/part5-security/hooks/dev-server-blocker.sh`

## 課程目標

理解 Pre-Tool-Use Hook 如何在工具執行前攔截並決定放行或阻斷，
學會 exit 0 / exit 1 / exit 2 三種 exit code 的差異，
掌握「內容掃描型」和「環境感知型」兩種 Hook 模式，
體會 exit 2 的「教育型防護」如何讓 AI 自行修正而非死擋。

## 工作目錄

`code-中文/part5-security/demo/06-Hook攔截器/`

---

## Step 1：閱讀 secret-scanner.sh，理解機密掃描邏輯

### Hook 觸發時機

`PreToolUse`——在 Claude 要執行任何工具**之前**觸發，Hook 可以決定是否讓工具真正執行。

### 監控工具

`Write`（建立/覆寫整個檔案）和 `Edit`（修改檔案特定區段）——兩個會把內容寫進檔案的工具。

### 七種機密 pattern

| 機密類型 | 正規表達式 pattern |
|---------|----------------|
| AWS Access Key | `AKIA[0-9A-Z]{16}` |
| GitHub PAT / App Token | `gh[ps]_[A-Za-z0-9]{36}` |
| Anthropic API Key | `sk-ant-[A-Za-z0-9\-]{95}` |
| OpenAI API Key | `sk-[A-Za-z0-9]{48}` |
| Google API Key | `AIza[0-9A-Za-z\-_]{35}` |
| Stripe Secret/Public Key | `(sk\|pk)_(test\|live)_[A-Za-z0-9]{24}` |
| RSA/EC/DSA 私鑰 | `-----BEGIN (RSA\|EC\|DSA) PRIVATE KEY-----` |

### 偵測到機密時的回應 JSON

```json
{"decision":"block","reason":"偵測到機密資訊：${NAMES[$i]}"}
```

### exit code 含義

| exit code | 含義 |
|-----------|------|
| `exit 0` | 允許工具繼續執行 |
| `exit 1` | 硬性阻斷，把 stderr 當錯誤訊息丟給**使用者**看 |
| `exit 2` | 帶反饋的阻斷，把 stdout 的 JSON 回傳給 **AI**，AI 讀到 reason 後可自行修正 |

### 實際結果

讀取 secret-scanner.sh 確認：PreToolUse 觸發、監控 Write + Edit 兩個工具、7 種機密 pattern（AWS/GitHub/Anthropic/OpenAI/Google/Stripe/私鑰）、exit 2 帶 JSON reason 反饋。

---

## Step 2：理解 exit 2 的三段回應機制

### 概念說明

```
Hook 的三種 exit code：

  exit 0  → 允許工具繼續執行（什麼都不做）
  exit 1  → 硬性阻斷，把 stderr 輸出當錯誤訊息丟給使用者
  exit 2  → 帶反饋的阻斷：把 stdout 的 JSON 回傳給 AI
              AI 讀到 reason 欄位，知道「為什麼被擋」
              AI 可以自行調整後重試

exit 2 的 JSON 格式：
{
  "decision": "block",
  "reason": "（給 AI 看的解釋：為什麼被擋、應該怎麼修）"
}
```

### exit 2 vs exit 1 的差異

| | exit 1 | exit 2 |
|--|--------|--------|
| 誰收到訊息 | 使用者（stderr 顯示在終端機） | AI（JSON 回傳到 AI context） |
| AI 知道原因嗎 | 不知道（AI 只知道「失敗了」） | 知道（reason 欄位說明原因） |
| AI 能自行修正嗎 | 不能（不知道要改什麼） | 能（知道是哪種機密被偵測到） |
| 使用體驗 | 錯誤訊息出現在終端機，AI 停住 | AI 自動嘗試移除機密後重試 |

### AI 讀到「偵測到機密資訊：ANTHROPIC」後的三步驟

1. **從內容移除 API Key**：把硬編碼的 `sk-ant-xxx` 改成環境變數引用 `os.environ["ANTHROPIC_API_KEY"]`
2. **重新嘗試 Write**：修正後的內容再次呼叫 Write
3. **告知使用者**：說明「我偵測到 API Key 被硬編碼，已改為環境變數讀取」

exit 2 讓 Hook 從「死擋」升級為「教育型防護」——攔截 + 給方向 + AI 自修正。

### exit 1 時 AI 能自行修正嗎

**不能**。exit 1 只把 stderr 丟給使用者，AI 的 context 裡沒有收到任何資訊，AI 只知道「Write 失敗了」，但不知道**為什麼**失敗。AI 只能停下來等使用者解釋，或嘗試完全不同的方向（可能猜錯）。

### exit 2 比 CLAUDE.md 說明更可靠的原因

| | CLAUDE.md 說「不要寫 API Key」 | exit 2 Hook |
|--|-------------------------------|------------|
| 觸發時機 | 讀取 CLAUDE.md 時（session 開頭） | 每次 Write/Edit 呼叫時 |
| AI 能忘記嗎 | 能（長對話後 CLAUDE.md 內容可能被壓縮出 context） | 不能（每次呼叫都重新執行） |
| 能偵測新格式嗎 | 不能（只靠 AI 的「記憶」） | 能（regex 可以更新） |
| 能抓到意外洩漏嗎 | 不能（AI 不知道 context 裡有 Key） | 能（掃描實際內容） |

### 實際結果

理解 exit 2 三段反饋：攔截 → reason JSON 給 AI → AI 自修正重試。exit 1 是死擋，exit 2 是教育型防護，CLAUDE.md 語言層約束無法取代系統層 Hook。

---

## Step 3：閱讀 dev-server-blocker.sh，理解環境感知攔截

### 攔截的操作類型

「**在非互動終端環境下啟動長期執行的開發伺服器**」。攔截的是「會佔據終端機、無法背景化的前景程序」這類行為，而非特定工具。

### 偵測的環境變數

`$TMUX`——檢查是否在 tmux session 內。`$TMUX` 有值 = 在 tmux 分割視窗中；`$TMUX` 為空 = 在單一終端機前景。

### 被攔截指令的原因

| 被攔截的指令 | 為什麼在非 TMUX 環境下危險？ |
|------------|--------------------------|
| `npm run dev` | 佔據終端機前景，Claude 無法繼續執行其他指令，session 卡住 |
| `yarn dev` / `pnpm dev` | 同上，AI 和使用者都失去對終端機的控制權 |
| `flask run` | 啟動 Flask 開發伺服器，持續輸出 log，終端機被鎖定 |
| `python manage.py runserver` | Django 開發伺服器，同樣佔用前景 |
| `next dev` / `vite` | 前端熱更新伺服器，持續監聽，Claude 無法繼續操作 |

### reason 建議的解法

> 「開發伺服器只允許在 tmux session 內啟動。」

言下之意：先 `tmux new -s dev` 或 `tmux split-window`，在 tmux 分割的視窗裡啟動伺服器，原視窗繼續讓 Claude 工作。

### 實際結果

理解環境感知型 Hook：讀 `$TMUX` 判斷執行環境，在非 tmux 環境阻斷所有前景開發伺服器指令，reason 明確告訴 AI 正確的解法（先開 tmux）。

---

## Step 4：設計你自己的 Pre-Tool-Use Hook

### 完整 Hook 腳本（保護 .env.production）

```bash
if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then
  if [[ "$FILE_PATH" == *".env.production"* ]]; then
    echo '{"decision":"block","reason":"禁止寫入 .env.production：這是生產環境設定，只能透過 CI/CD 系統更新，不可在本機直接修改。"}'
    exit 2
  fi
fi
```

### reason 欄位涵蓋三件事

1. **為什麼被擋**：這是生產環境設定
2. **應該怎麼做**：透過 CI/CD 系統更新
3. **不應該做什麼**：不可本機直接修改

### Hook vs Deny 規則的本質差別

| 比較 | Deny 規則 | Pre-Tool-Use Hook |
|------|---------|-----------------|
| 設定位置 | settings.json | hooks/ 目錄下的腳本 |
| 判斷邏輯複雜度 | 只能做 glob pattern match（靜態） | 可以執行任意 shell 邏輯（動態） |
| 能讀取環境資訊嗎 | 不能 | 能（`$TMUX`、`$NODE_ENV`、`$CI` 等） |
| 能給 AI 詳細說明嗎 | 不能（只說「Permission denied」） | 能（exit 2 + reason JSON = AI 知道原因和修正方向） |
| 適用場景 | 知道要擋什麼（靜態規則） | 知道在什麼情況才擋（動態邏輯） |

### 實際結果

設計完整 Hook：Write/Edit 攔截 + 路徑比對 `.env.production` + exit 2 帶 reason。理解 Hook vs Deny 的選擇原則：靜態規則 → Deny，動態邏輯（環境感知/內容掃描）→ Hook。

---

## 本課重點

```
Pre-Tool-Use Hook 執行時機：
  工具被呼叫 → Hook 先執行 → 決定放行 → 工具才真正執行

三種 exit code：
  exit 0 → 放行
  exit 1 → 硬擋（使用者看到 stderr）
  exit 2 → 智慧擋（AI 看到 reason JSON，可自行修正）

exit 2 的反饋迴圈：
  Hook 攔截 → reason 給 AI → AI 修正 → 重試
  從「死擋」升級為「教育型防護」

兩種核心 Hook 模式：
  內容掃描（secret-scanner）：掃描寫入內容的 pattern
  環境感知（dev-server-blocker）：讀環境變數決定是否允許

Hook vs Deny 的選擇：
  靜態規則（知道要擋什麼）→ Deny
  動態邏輯（知道在什麼情況才擋）→ Hook
```
