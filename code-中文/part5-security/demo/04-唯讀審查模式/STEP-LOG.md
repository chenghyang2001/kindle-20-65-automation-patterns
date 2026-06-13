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

### 閱讀任務

打開 `permissions/readonly-review.json`，回答：

1. `defaultMode: "dontAsk"` 代表什麼？
   （提示：這個模式下，沒有被 deny/allow 明確規定的操作，AI 會怎麼做？）

   答：

2. Deny 清單封鎖了哪些工具？

   | 被封鎖的工具 | 這個工具能做什麼 | 為什麼要封鎖 |
   |------------|--------------|-----------|
   | `Bash` | | |
   | `Edit` | | |
   | `Write` | | |
   | `WebFetch` | | |
   | `mcp__*` | | |

3. Allow 清單只開放了哪些操作？

   答：

4. `Grep` 和 `Glob` 被設為 Allow，這兩個工具能做什麼？為什麼 Code Review 需要它們？

   答：

### 實際結果

（演練時填入）

---

## Step 2：比較 readonly-review 和第 4 章的 `--permission-mode plan`

### 對比表

| 比較維度 | `readonly-review.json`（本機設定） | `--permission-mode plan`（CLI 引數） |
|---------|--------------------------------|----------------------------------|
| 作用範圍 | 這個專案的所有對話 | 單次 `claude -p` 呼叫 |
| 設定方式 | 放進 `.claude/settings.json` | 在 CLI 指令加引數 |
| 哪些工具被封鎖 | Bash、Edit、Write、WebFetch | 所有寫入類工具 |
| 適用場景 | | |

回答：

1. 如果你每天都在做 Code Review，哪種方式比較方便？為什麼？

   答：

2. 如果是 GitHub Actions 裡的自動化 Code Review，哪種方式更適合？

   答：

3. `mcp__*` 被 Deny 了。這代表什麼？為什麼 Code Review 時要封鎖 MCP 工具？

   答：

### 實際結果

（演練時填入）

---

## Step 3：實際驗證唯讀設定的效果

### 模擬場景

假設你用 `readonly-review.json` 的設定開啟了 Claude，然後下了以下指令：

**指令 1**：「幫我分析 src/auth.ts 有沒有 SQL injection 漏洞」

1. 這個任務需要哪些工具？

   答：

2. 這些工具在 readonly-review 的設定下，哪些被允許，哪些被封鎖？

   | 需要的工具 | 允許 / 封鎖 |
   |-----------|-----------|
   | Read(src/auth.ts) | |
   | Grep（搜尋特定 pattern） | |
   | Edit（如果 AI 想順手修復） | |

3. AI 最終能完成這個任務嗎？品質會受影響嗎？

   答：

**指令 2**：「幫我修復 src/auth.ts 裡找到的 SQL injection 漏洞」

1. 這個任務需要哪些工具？

   答：

2. AI 能完成這個修復任務嗎？

   答：

3. 這說明了 readonly-review 設定適合什麼、不適合什麼？

   答：

### 實際結果

（演練時填入）

---

## Step 4：設計「Pull Request 守門員」的唯讀設定

### 情境

你要設計一個 AI，專門在 Pull Request 被建立時自動執行審查，它必須：

- 可以讀取所有 `src/` 和 `tests/` 下的檔案
- 可以搜尋（Grep）和找檔案（Glob）
- **不能**修改任何檔案（保護 PR 內容完整性）
- **不能**執行任何指令（避免觸發不預期的副作用）
- **不能**存取網路（避免資訊外洩）

填入設定：

```json
{
  "defaultMode": "___________",
  "permissions": {
    "deny": [
      （填入：封鎖所有寫入工具）
      （填入：封鎖網路工具）
      （填入：封鎖 MCP 工具）
    ],
    "allow": [
      （填入：允許讀取 src/ 和 tests/）
      （填入：允許搜尋工具）
    ]
  }
}
```

### 實際結果

（演練時填入）

---

## 本課重點

```
唯讀審查模式的兩個關鍵設定：

  defaultMode: "dontAsk"
    → 沒有明確規定的操作 = 直接拒絕（不詢問）
    → 配合嚴格的 Deny 清單，形成「最小權限」環境
    → AI 只能做你明確 Allow 的那些事

  Deny 的封鎖層次：
    Bash    → 無法執行任何 shell 指令
    Edit    → 無法修改既有檔案
    Write   → 無法建立新檔案
    WebFetch → 無法連網
    mcp__*  → 無法呼叫任何 MCP 工具

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
