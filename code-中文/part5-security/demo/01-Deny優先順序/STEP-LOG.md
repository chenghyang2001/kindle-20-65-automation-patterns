# 第 1 課演練記錄：Deny > Ask > Allow 優先順序

> 對應文件：`code-中文/part5-security/permissions/deny-sensitive-files.json`

## 課程目標

理解為什麼 AI 的資安守門最致命的破口往往是「疲憊的工程師盲目按下允許」，
學會 Deny > Ask > Allow 的絕對優先順序，
掌握用 Deny 規則保護 `.env` 和 `secrets/` 等敏感檔案。

## 工作目錄

`code-中文/part5-security/demo/01-Deny優先順序/`

---

## Step 1：閱讀 deny-sensitive-files.json，理解 Deny 的絕對性

### 閱讀任務

打開 `permissions/deny-sensitive-files.json`，回答：

1. 這個設定保護了哪些檔案路徑？（列出所有 deny 規則）

   答：

2. Deny 規則同時封鎖了哪兩種操作？（不只是讀取）

   答：

3. 為什麼 `.env.*` 要用萬用字元而不只是 `.env`？
   （想想 `.env.local`、`.env.production` 這些檔案）

   答：

4. 為什麼要設置 Deny 規則，而不是在 CLAUDE.md 裡寫「不要讀取 .env 檔案」？

   | 方式 | 機制 | AI 能繞過嗎 |
   |------|------|-----------|
   | CLAUDE.md 說「不要讀」 | | |
   | Deny 規則 | | |

### 實際結果

（演練時填入）

---

## Step 2：理解 Deny > Ask > Allow 的優先順序

### 概念說明

當系統遇到一個工具呼叫請求，判斷流程：

```
AI 要執行某個操作
        ↓
有沒有 Deny 規則命中？
  是 → 立刻拒絕，不給 AI 任何解釋或商量的空間
  否 ↓
有沒有 Ask 規則命中？
  是 → 彈出詢問框，等使用者手動確認
  否 ↓
有沒有 Allow 規則命中？
  是 → 自動允許，不打擾使用者
  否 → 根據預設模式決定
```

### 思考練習

情境：AI 正在幫你除錯一個資料庫連線問題。它說：
> 「為了確認資料庫連線字串是否正確，我必須讀取 `.env` 檔案，
> 因為問題可能是 DB_HOST 或 DB_PORT 設定錯了。」

1. 這個理由聽起來合理嗎？（答誠實）

   答：

2. 如果是凌晨三點你趕 deadline，你會不會因為理由合理就按下「允許」？

   答：

3. 有了 Deny 規則後，AI 的讀取請求在哪個時間點被攔截？
   （在 AI 說理由之前、之後，還是你按「允許」之後？）

   答：

4. 這說明了什麼防禦哲學？

   答：

### 實際結果

（演練時填入）

---

## Step 3：設計你自己的 Deny 規則

### 情境

你的專案有以下需要保護的敏感路徑：

```
.env                    ← 主要環境變數
.env.local              ← 本機開發環境變數
.env.production         ← 正式環境變數
secrets/api-keys.json   ← API 金鑰
secrets/ssl/            ← SSL 憑證目錄
credentials.json        ← Google OAuth 憑證
```

填入完整的 Deny 設定（參考 deny-sensitive-files.json 的格式）：

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      （繼續填入其他規則）
    ]
  }
}
```

### 確認你的設計

| 保護的檔案/路徑 | 你的 Deny 規則 | 涵蓋了嗎？ |
|--------------|-------------|---------|
| .env | | |
| .env.local | | |
| .env.production | | |
| secrets/api-keys.json | | |
| secrets/ssl/ 整個目錄 | | |
| credentials.json | | |

### 實際結果

（演練時填入）

---

## Step 4：思考 Deny 的邊界

### 討論問題

1. 如果把所有東西都設成 Deny，AI 就什麼都做不了。
   Deny 規則應該只保護什麼類型的路徑？

   答：

2. `Read(./secrets/**)` 保護的是 secrets/ 目錄下的所有東西。
   但 `**` 和 `*` 有什麼差別？（想想巢狀子目錄的情況）

   答：

3. 如果你既需要 Deny 保護又需要 AI 偶爾查看環境變數格式，
   有什麼比「寫進 Deny 規則」更好的方式？

   答：

### 實際結果

（演練時填入）

---

## 本課重點

```
Deny > Ask > Allow 的絕對鐵律：
  Deny 命中 → 立刻拒絕（系統層攔截，不給 AI 開口的機會）
  Ask 命中  → 彈出詢問框（需要人類手動確認）
  Allow 命中 → 自動執行（不打擾使用者）

Deny 的核心價值：
  防止「疲憊工程師」效應
  不管 AI 的理由多合理、多有說服力
  系統在工具發動的瞬間就阻斷，不給「被說服」的機會

必須設為 Deny 的路徑類型：
  .env / .env.* — 環境變數（含資料庫密碼、API Key）
  secrets/**  — 機密目錄
  credentials.json — OAuth 憑證
  ~/.*        — 家目錄下的所有隱藏檔案

記住：設計 Deny 規則時，想的是「凌晨三點最累的那個同事」
     他會不會因為 AI 說的理由很合理就按允許？有了 Deny，他沒有機會
```
