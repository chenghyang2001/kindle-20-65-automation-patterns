# 第 6 課演練記錄：Hook 攔截器（Pre-Tool-Use Hooks）

> 對應文件：
>
> - `code-中文/part5-security/hooks/secret-scanner.sh`
> - `code-中文/part5-security/hooks/dev-server-blocker.sh`

## 課程目標

理解 Pre-Tool-Use Hook 如何在工具執行前插入自定義邏輯，
學會用 `exit 2` + JSON 回應機制攔截危險操作並給 AI 明確的修正方向，
掌握「機密掃描」和「環境感知」兩種核心 Hook 模式。

## 工作目錄

`code-中文/part5-security/demo/06-Hook攔截器/`

---

## Step 1：閱讀 secret-scanner.sh，理解機密掃描邏輯

### 閱讀任務

打開 `hooks/secret-scanner.sh`，回答：

1. 這個 Hook 在什麼事件觸發？（看 Hook 類型）

   答：

2. 它監控哪兩個工具的呼叫？

   答：

3. 填入它掃描的 7 種機密 pattern：

   | 機密類型 | 正規表達式 pattern |
   |---------|----------------|
   | AWS Access Key | `AKIA[0-9A-Z]{16}` |
   | GitHub Personal Access Token | |
   | GitHub App / OAuth Token | |
   | Anthropic API Key | |
   | OpenAI API Key | |
   | Google API Key | |
   | Stripe Secret Key | |
   | RSA Private Key | |

4. 當 Hook 偵測到機密時，它回傳什麼格式的回應？

   ```json
   （抄下 secret-scanner.sh 的回應 JSON）
   ```

5. `exit 2` 的含義是什麼？（提示：exit 0 = 允許，exit 1 = ？，exit 2 = ？）

   答：

### 實際結果

（演練時填入）

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

### 思考問題

1. secret-scanner.sh 用的是 `exit 2`，而不是 `exit 1`。
   從 AI 的角度，這兩種有什麼不同的體驗？

   答：

2. reason 欄位裡寫的是「偵測到機密資訊：NAME」。
   AI 讀到這個訊息後，下一步最可能做什麼？

   答：

3. 如果改成 `exit 1`，AI 能自行修正嗎？

   答：

4. 為什麼 `exit 2` 比「在 CLAUDE.md 裡寫不要把 API Key 寫進檔案」更可靠？

   答：

### 實際結果

（演練時填入）

---

## Step 3：閱讀 dev-server-blocker.sh，理解環境感知攔截

### 閱讀任務

打開 `hooks/dev-server-blocker.sh`，回答：

1. 這個 Hook 攔截的是哪類操作？（不是哪個工具，而是哪類「行為」）

   答：

2. 它偵測的環境變數是什麼？這個變數代表什麼環境？

   答：

3. 被攔截的指令有哪些？填入表格：

   | 被攔截的指令 | 為什麼在非 TMUX 環境下危險？ |
   |------------|--------------------------|
   | `npm run dev` | |
   | `yarn dev` | |
   | `flask run` | |
   | `uvicorn *` | |
   | `python -m http.server` | |

4. 它回傳的 reason 裡建議使用者怎麼做？

   答：

### 實際結果

（演練時填入）

---

## Step 4：設計你自己的 Pre-Tool-Use Hook

### 情境

你想設計一個 Hook，防止 AI 在生產環境的 `.env.production` 裡寫入任何內容。
邏輯：如果 AI 要呼叫 Write 或 Edit，而且目標路徑包含 `.env.production`，就攔截。

填入 shell 腳本的核心邏輯：

```bash
#!/bin/bash

# 從標準輸入讀取 Hook 事件（JSON 格式）
INPUT=$(cat)

# 取得工具名稱
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))")

# 取得目標路徑（Write 工具的 file_path 欄位）
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))")

# 判斷邏輯：如果工具是 Write 或 Edit，且路徑含 .env.production
if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then
  if [[ "$FILE_PATH" == *".env.production"* ]]; then
    echo '（填入你的 JSON 回應）'
    exit ___  # 填入正確的 exit code
  fi
fi

exit 0
```

完成後，回答：

1. 你的 reason 欄位寫什麼？要讓 AI 知道哪些資訊？

   答：

2. 這個 Hook 和 Deny 規則（`Edit(.env.production)`）有什麼本質差別？

   | 比較 | Deny 規則 | Pre-Tool-Use Hook |
   |------|---------|-----------------|
   | 設定位置 | settings.json | hooks/ 目錄下的腳本 |
   | 判斷邏輯複雜度 | 只能做 pattern match | |
   | 能讀取環境資訊嗎 | 不能 | |
   | 能給 AI 詳細說明嗎 | 不能（只會說「被拒絕」） | |

### 實際結果

（演練時填入）

---

## 本課重點

```
Pre-Tool-Use Hook 的執行時機：
  工具被呼叫 → Hook 先執行 → 決定是否放行 → 工具才真正執行

  和 Deny 規則的差別：
  Deny 規則 = 靜態 pattern match（規則寫死）
  Hook     = 動態腳本（可以讀環境變數、查檔案內容、呼叫外部 API）

exit 2 的反饋迴圈：
  Hook 攔截 → 給 AI reason → AI 知道「為什麼被擋」
  → AI 自行修正（移除機密 / 換環境）→ 重試
  這讓 Hook 從「死擋」升級為「教育型防護」

兩種核心 Hook 模式：

  模式 1：內容掃描（secret-scanner）
    「檢查 AI 要寫入的內容有沒有問題」
    觸發：Write / Edit
    邏輯：從 tool_input.content 掃描 pattern
    適用：機密偵測、PII 偵測、硬編碼路徑偵測

  模式 2：環境感知（dev-server-blocker）
    「根據當前環境決定是否允許某操作」
    觸發：Bash
    邏輯：讀環境變數（$TMUX、$CI、$NODE_ENV）決定
    適用：防止 CI 環境啟動開發伺服器、防止生產環境執行危險指令

Hook 是 Deny 規則的「升階版」：
  Deny：我知道要擋什麼（靜態）
  Hook：我知道在什麼情況下才擋（動態）
```
