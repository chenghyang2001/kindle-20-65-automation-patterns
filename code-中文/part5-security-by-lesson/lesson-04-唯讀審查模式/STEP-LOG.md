# 第 4 課演練記錄：唯讀審查模式（Plan Mode）

> 對應文件：`code-中文/part5-security/permissions/readonly-review.json`

## 課程目標

理解 Plan Mode（唯讀計畫模式）如何把 AI 鎖定為「只能看，不能動」，
學會用 `defaultMode: dontAsk` + 嚴格 Deny 組合出完整的 Code Review 專用設定，
體會「最小權限原則」在實際 Code Review 場景的應用。

## 工作目錄

`code-中文/part5-security/demo/04-唯讀審查模式/`

---

## Step 1：閱讀 readonly-review.json，理解唯讀設定的組合

### 回答

1. `defaultMode: "dontAsk"` 代表什麼？

   答：沒有被 deny/allow 明確規定的操作，AI **直接拒絕執行，不彈出詢問框**。
   - `dontAsk` = 「只有白名單裡的事才能做，其他全部靜默拒絕」
   - 對比：default 模式下未被規定的操作 = 彈出詢問框讓使用者決定

2. Deny 清單封鎖了哪些工具？

   | 被封鎖的工具 | 這個工具能做什麼 | 為什麼要封鎖 |
   |------------|--------------|-----------|
   | `Bash` | 執行任何 shell 指令 | 防止 AI 跑測試/安裝套件/刪除檔案等副作用 |
   | `Edit` | 修改既有檔案（in-place 編輯） | Code Review 絕對不能改程式碼 |
   | `Write` | 建立新檔案或完整覆寫 | 防止 AI「幫你新增一個修復文件」 |
   | `WebFetch` | 從 URL 抓取網頁內容 | 防止程式碼內容外洩 / Prompt Injection via URL |
   | `mcp__*` | 呼叫任何 MCP 工具（Notion/Gmail/NotebookLM 等） | Code Review 不需要外部服務，封鎖防止資訊外洩 |

3. Allow 清單只開放了哪些操作？

   答：僅 4 條：
   - `Read(./src/**)` — 讀取 src/ 下所有檔案
   - `Read(./tests/**)` — 讀取 tests/ 下所有測試檔
   - `Grep` — 在檔案內容中搜尋特定 pattern
   - `Glob` — 按 glob 模式找出符合條件的檔案路徑清單

4. `Grep` 和 `Glob` 被設為 Allow，Code Review 為什麼需要它們？

   答：
   - `Grep`：搜尋「所有用了 `eval(` 的地方」「所有沒有 try/catch 的 async 函式」「所有明文密碼 pattern」——比逐檔 Read 有效率
   - `Glob`：找出「所有 *.test.ts 確認測試覆蓋率」「所有 api/*.ts 確認認證端點完整性」

   兩者都是**純查詢，零副作用**——Code Review 的核心能力。

### 實際結果

讀取 readonly-review.json 確認：`defaultMode: dontAsk` + 5 條 Deny（Bash/Edit/Write/WebFetch/mcp__*）+ 4 條 Allow（Read src、Read tests、Grep、Glob）。

---

## Step 2：比較 readonly-review.json 和 `--permission-mode plan`

### 對比表

| 比較維度 | `readonly-review.json`（本機設定） | `--permission-mode plan`（CLI 引數） |
|---------|--------------------------------|----------------------------------|
| 作用範圍 | 這個專案的**所有對話**（永久生效） | **單次** `claude -p` 呼叫（一次性） |
| 設定方式 | 放進 `.claude/settings.json` | 在 CLI 指令加引數 |
| 哪些工具被封鎖 | 精確指定（Bash/Edit/Write/WebFetch/mcp__*） | 所有寫入類工具（系統層全封） |
| 適用場景 | 固定的 Code Review 工作區 | CI pipeline 的一次性掃描 |

### 回答

1. 如果你每天都在做 Code Review，哪種方式比較方便？

   答：`readonly-review.json`。設定一次、永久生效，不需要每次在 CLI 加引數。專案層級設定讓「這個倉庫永遠是唯讀審查模式」，不依賴使用者記得加引數。

2. GitHub Actions 裡的自動化 Code Review，哪種更適合？

   答：`--permission-mode plan`。理由：
   (1) CI 環境不應依賴持久化設定檔（settings.json 可能不在 CI 容器裡）
   (2) 引數在 YAML 裡明確可見，方便 code review CI 設定本身
   (3) 一次性呼叫不需要持久設定

3. 為什麼 Code Review 時要封鎖 `mcp__*`？

   答：MCP 工具可以：
   - `mcp__gmail__send_email` — 把審查結果送到任意信箱（資訊外洩）
   - `mcp__notebooklm__add_notebook` — 把程式碼上傳到第三方服務
   - `mcp__github__create_pull_request` — AI 自己開 PR（不在計畫中的副作用）

   Code Review 只需要讀本地檔案，任何外部服務存取都是不必要的攻擊面。

### 實際結果

理解兩種唯讀方式的差異：settings.json 適合固定工作區（設一次永久），plan mode 適合 CI 一次性呼叫（引數明確可 review）。

---

## Step 3：實際驗證唯讀設定的效果

### 指令 1：「幫我分析 src/auth.ts 有沒有 SQL injection 漏洞」

1. 工具需求分析：

   | 需要的工具 | 允許 / 封鎖 |
   |-----------|-----------|
   | `Read(src/auth.ts)` | ✅ 允許（在 `Read(./src/**)` 範圍內） |
   | `Grep`（搜尋特定 pattern） | ✅ 允許 |
   | `Edit`（AI 想順手修復） | ❌ 封鎖（在 Deny 清單） |

2. AI 能完成審查任務嗎？

   答：**能，且品質完整**。AI 可以讀取整個檔案、用 Grep 搜尋所有 SQL 相關 pattern，產出完整漏洞分析報告。唯一差別是它「無法順手修復」——這正是我們想要的行為。

### 指令 2：「幫我修復 src/auth.ts 裡找到的 SQL injection 漏洞」

1. AI 能完成修復任務嗎？

   答：**不能**。Edit 被封鎖，任何嘗試修改 `src/auth.ts` 的呼叫都會被拒絕。

2. 這說明了 readonly-review 適合什麼、不適合什麼？

   | 任務 | 適合 readonly-review？ |
   |------|---------------------|
   | 找出安全漏洞、寫審查報告 | ✅ 非常適合 |
   | 提供修復建議（文字說明） | ✅ 適合（只需要說，不需要寫） |
   | 實際修復漏洞 | ❌ 不適合，需要切換到有 Edit 權限的模式 |

   正確工作流：**唯讀審查 → 切換模式修復 → 再次唯讀審查驗證**

### 實際結果

模擬確認：讀取+分析任務完整可行；修復任務被正確攔截。readonly-review 設計精準對應「只看不動」的審查職責。

---

## Step 4：設計「Pull Request 守門員」的唯讀設定

### 完整設定

```json
{
  "defaultMode": "dontAsk",
  "permissions": {
    "deny": [
      "Bash",
      "Edit",
      "Write",
      "WebFetch",
      "mcp__*"
    ],
    "allow": [
      "Read(./src/**)",
      "Read(./tests/**)",
      "Grep",
      "Glob"
    ]
  }
}
```

### 觀察

和 `readonly-review.json` 完全一樣——因為「PR 守門員」的需求和「Code Review 唯讀模式」的設計完全一致。這說明 `readonly-review.json` 的設計本身就是最小權限原則的完整體現，不需要增加任何東西。

### 實際結果

設計完成：`defaultMode: dontAsk` + 5 條 Deny + 4 條 Allow。與原始 readonly-review.json 完全吻合，驗證了最小權限原則的設計沒有多餘規則。

---

## 本課重點

```
唯讀審查模式的兩個關鍵設定：

  defaultMode: "dontAsk"
    → 沒有明確規定的操作 = 直接拒絕（不詢問）
    → 配合嚴格的 Deny 清單，形成「最小權限」環境
    → AI 只能做你明確 Allow 的那些事

  Deny 的封鎖層次：
    Bash     → 無法執行任何 shell 指令
    Edit     → 無法修改既有檔案
    Write    → 無法建立新檔案
    WebFetch → 無法連網
    mcp__*   → 無法呼叫任何 MCP 工具

兩種唯讀方式的選擇：
  本機固定工作區 → settings.json（設一次、永久生效）
  CI 一次性掃描 → --permission-mode plan（引數明確、可 review）

Code Review 唯讀的意義：
  AI 像一位「有存取證但沒有鑰匙」的稽查員
  → 可以看所有文件（Read）
  → 可以搜尋和比對（Grep / Glob）
  → 但絕對無法「幫你改文件」或「說我順手修好了」

最小權限原則（Principle of Least Privilege）：
  只給這個任務真正需要的最少權限
  Code Review 只需要讀 → 只給讀
  不多給「說不定以後有用」的權限
```
