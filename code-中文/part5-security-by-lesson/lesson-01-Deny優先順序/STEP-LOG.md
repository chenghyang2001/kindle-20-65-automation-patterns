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

   答：共 7 條規則：
   - `Read(./.env)` / `Edit(./.env)` — 主要環境變數
   - `Read(./.env.*)` / `Edit(./.env.*)` — 所有 .env 衍生（.env.local、.env.production 等）
   - `Read(./secrets/**)` / `Edit(./secrets/**)` — secrets/ 整個目錄樹
   - （credentials 讀取未列入，是個漏洞——只封了 secrets/，未封 credentials.json）

2. Deny 規則同時封鎖了哪兩種操作？（不只是讀取）

   答：**Read（讀取）** 和 **Edit（編輯/寫入）** 兩種操作都被封鎖。只封讀不封寫是漏洞——AI 無法讀但仍可竄改。

3. 為什麼 `.env.*` 要用萬用字元而不只是 `.env`？
   （想想 `.env.local`、`.env.production` 這些檔案）

   答：`.env` 只保護主環境變數檔，但現代專案通常有多個變體：`.env.local`（本機）、`.env.production`（正式環境）、`.env.test`（測試）。萬用字元 `.env.*` 一條規則涵蓋所有衍生，不需逐一列出。

4. 為什麼要設置 Deny 規則，而不是在 CLAUDE.md 裡寫「不要讀取 .env 檔案」？

   | 方式 | 機制 | AI 能繞過嗎 |
   |------|------|-----------|
   | CLAUDE.md 說「不要讀」 | 語言層約束，AI 依文字指示行動 | **能** — AI 可被後續 prompt 說服「這次例外有必要」 |
   | Deny 規則 | 系統層鎖定，harness 在工具呼叫前攔截 | **不能** — 攔截發生在工具發動瞬間，不到 AI 決策層 |

### 實際結果

讀取 deny-sensitive-files.json 確認：7 條 Deny 規則封鎖 Read + Edit，萬用字元涵蓋 .env 衍生和 secrets/ 目錄樹。

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

   答：**非常合理**。除錯資料庫連線時確認環境變數是標準操作，幾乎沒有工程師能立刻反駁這個邏輯。這正是 Deny 規則存在的原因——「合理的理由」比「明顯可疑的要求」更危險，因為更容易通過人類的判斷篩選。

2. 如果是凌晨三點你趕 deadline，你會不會因為理由合理就按下「允許」？

   答：**幾乎一定會**。凌晨三點疲憊、壓力大、急著解決問題時，判斷力最弱，被「合理理由」說服的機率最高。這就是「疲憊工程師效應」——人類的安全決策能力在壓力下大幅下降。

3. 有了 Deny 規則後，AI 的讀取請求在哪個時間點被攔截？
   （在 AI 說理由之前、之後，還是你按「允許」之後？）

   答：**在 AI 嘗試呼叫 Read 工具的瞬間**——早於 AI 說出任何理由，也早於使用者看到任何詢問框。Deny 規則在 harness 層攔截，AI 甚至來不及「解釋」就已被拒絕，使用者根本不會看到詢問框。

4. 這說明了什麼防禦哲學？

   答：**移除決策點，不依賴人類判斷**。傳統安全模型假設人類能在壓力下做出正確決策（Ask = 人類把關）；Deny 規則認識到人類判斷力有限，直接在系統層消除決策機會。比 Ask 更強的不是「更嚴格的審查」，而是「根本不給審查的機會」。

### 實際結果

理解 Deny 的攔截時機：工具呼叫瞬間、早於 AI 解釋、早於使用者看到詢問框。防禦哲學：移除決策點 > 依賴人類判斷。

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
      "Edit(./.env)",
      "Read(./.env.*)",
      "Edit(./.env.*)",
      "Read(./secrets/**)",
      "Edit(./secrets/**)",
      "Read(./credentials.json)",
      "Edit(./credentials.json)"
    ]
  }
}
```

### 確認你的設計

| 保護的檔案/路徑 | 你的 Deny 規則 | 涵蓋了嗎？ |
|--------------|-------------|---------|
| .env | `Read(./.env)` + `Edit(./.env)` | ✅ |
| .env.local | `Read(./.env.*)` + `Edit(./.env.*)` | ✅（萬用字元） |
| .env.production | `Read(./.env.*)` + `Edit(./.env.*)` | ✅（萬用字元） |
| secrets/api-keys.json | `Read(./secrets/**)` + `Edit(./secrets/**)` | ✅（`**` 含單層文件） |
| secrets/ssl/ 整個目錄 | `Read(./secrets/**)` + `Edit(./secrets/**)` | ✅（`**` 遞迴含子目錄） |
| credentials.json | `Read(./credentials.json)` + `Edit(./credentials.json)` | ✅ |

注意：原始 deny-sensitive-files.json 未設 `Read/Edit(./credentials.json)`——credentials 只被間接保護（若在 secrets/ 目錄下），若放在根目錄則是漏洞。

### 實際結果

設計完整 Deny JSON：8 條規則，Read + Edit 成對出現，涵蓋全部 6 條敏感路徑。發現原檔案 credentials.json 保護缺口。

---

## Step 4：思考 Deny 的邊界

### 討論問題

1. 如果把所有東西都設成 Deny，AI 就什麼都做不了。
   Deny 規則應該只保護什麼類型的路徑？

   答：**「洩漏後不可逆損害」的機密**：
   - 應設 Deny：`.env` / `secrets/` / 私鑰（`.pem`、`.key`）/ OAuth 憑證 / 資料庫備份
   - 不應設 Deny：一般 src/ 程式碼、文件、測試資料、node_modules/

   判斷原則：洩漏後能立刻造成損害（帳戶被盜、資料洩漏、資料庫被存取）→ Deny；洩漏後只是「不太好」→ Ask 或 Allow。

2. `Read(./secrets/**)` 保護的是 secrets/ 目錄下的所有東西。
   但 `**` 和 `*` 有什麼差別？（想想巢狀子目錄的情況）

   答：
   - `*`：單一層級，不含 `/`。`secrets/*.json` 匹配 `secrets/key.json`，**不**匹配 `secrets/ssl/cert.pem`
   - `**`：任意層級，遞迴含子目錄。`secrets/**` 同時匹配 `secrets/key.json` 和 `secrets/ssl/cert.pem` 和更深的任何路徑

   保護整個目錄樹一律用 `**`；只保護目錄直接子文件才用 `*`。

3. 如果你既需要 Deny 保護又需要 AI 偶爾查看環境變數格式，
   有什麼比「寫進 Deny 規則」更好的方式？

   答：不改 Deny 規則，改用替代方案：
   - **提供 `.env.example`**：去掉真實值的範本（`DB_HOST=<your-host>`），AI 可讀格式，不碰真實值
   - **手動摘要貼入對話**：把「結構」（不含真實值）貼進對話框
   - **單次逃生門**：`FORCE_DIRECT_WRITE=1` 或專案臨時移除 Deny——用完即撤，不永久改規則

   核心原則：Deny 規則是靜態防線，不因個案調整；個案需求用其他方式繞，不動 Deny。

### 實際結果

理解 Deny 邊界：只保護不可逆損害的機密；`**` vs `*` 差別（遞迴 vs 單層）；`.env.example` 是不改 Deny 規則的最佳替代方案。

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

設計要點：
  Read + Edit 必須成對出現（只封讀 = 漏洞）
  目錄樹用 ** 不用 *（** 遞迴含子目錄，* 只含單層）
  個案需求用 .env.example 解決，不動 Deny 規則本身

記住：設計 Deny 規則時，想的是「凌晨三點最累的那個同事」
     他會不會因為 AI 說的理由很合理就按允許？有了 Deny，他沒有機會
```
