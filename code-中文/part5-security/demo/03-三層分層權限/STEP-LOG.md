# 第 3 課演練記錄：三層分層權限（Deny / Ask / Allow）

> 對應文件：`code-中文/part5-security/permissions/layered-permissions.json`

## 課程目標

學會把操作分成「絕對禁止 / 需要確認 / 自動允許」三個層次，
理解每個層次背後的風險判斷邏輯，
掌握完整的分層權限設計，讓 AI 既能流暢工作又不踩地雷。

## 工作目錄

`code-中文/part5-security/demo/03-三層分層權限/`

---

## Step 1：閱讀 layered-permissions.json，分析三層設計

### 閱讀任務

打開 `permissions/layered-permissions.json`，填入：

**Deny（絕對禁止）：**

| 規則 | 為什麼是 Deny 而不是 Ask？ |
|------|------------------------|
| `Bash(git push *)` | |
| `Bash(npm publish *)` | |
| `Bash(rm -rf *)` | |
| `Read(./.env)` | |
| `Read(./.env.*)` | |
| `Read(./secrets/**)` | |

**Ask（需要人類確認）：**

| 規則 | 為什麼是 Ask 而不是 Deny 或 Allow？ |
|------|----------------------------------|
| `Bash(git commit *)` | |
| `Bash(docker run *)` | |

**Allow（自動允許）：**

| 規則 | 為什麼是 Allow 而不是 Ask？ |
|------|--------------------------|
| `Bash(npm run lint)` | |
| `Bash(npm run test *)` | |
| `Bash(git status)` | |
| `Read(src/**)` | |
| `Edit(src/**)` | |

### 實際結果

（演練時填入）

---

## Step 2：理解三層之間的風險判斷框架

### 填入風險矩陣

把操作按「可逆性」和「影響範圍」分類：

| | 低影響範圍 | 高影響範圍 |
|---|-----------|-----------|
| **可逆操作** | Allow（如 `git diff`） | Ask（如 `git commit`） |
| **不可逆操作** | Ask（視情況） | **Deny**（如 `git push --force`） |

回答：

1. `git commit` 為什麼是 Ask 而不是 Allow？
   （提示：commit 之後還能 undo，但...）

   答：

2. `npm run lint` 為什麼是 Allow 而不是 Ask？
   （提示：lint 不會修改任何東西）

   答：

3. `docker run *` 為什麼是 Ask？它可能做什麼危險的事？

   答：

4. 如果你把所有操作都設成 Ask，會有什麼問題？

   答：

### 實際結果

（演練時填入）

---

## Step 3：設計一套「AI 協助 Code Review」的分層權限

### 情境

你希望 AI 幫你做 Code Review，它需要：

- 讀取 `src/` 和 `tests/` 目錄下的所有檔案
- 執行測試查看結果（`npm run test`）
- 執行 lint 查看錯誤（`npm run lint`）
- 查看 git diff 瞭解本次變更
- **不允許**修改任何檔案
- **不允許**執行 git commit 或 push

填入完整設定：

```json
{
  "permissions": {
    "deny": [
      （填入：禁止修改檔案的規則）
      （填入：禁止 git push 和 commit 的規則）
    ],
    "ask": [
      （有沒有需要詢問的操作？）
    ],
    "allow": [
      （填入：允許讀取 src/ 和 tests/ 的規則）
      （填入：允許執行測試和 lint 的規則）
      （填入：允許查看 git diff 的規則）
    ]
  }
}
```

### 實際結果

（演練時填入）

---

## Step 4：對比三份 permissions 設定的用途差異

### 比較三個設定檔

| 設定檔 | 主要用途 | Deny 的重點 | Allow 的重點 |
|--------|---------|-----------|------------|
| `deny-sensitive-files.json` | | | |
| `bash-patterns.json` | | | |
| `layered-permissions.json` | | | |

### 思考

1. 可不可以把三個設定檔合併成一個？有什麼優缺點？

   答：

2. 為什麼 `layered-permissions.json` 把 `Allow(Edit(src/**))` 放進去？
   Edit 不就是修改檔案嗎，怎麼反而是 Allow？

   答：

### 實際結果

（演練時填入）

---

## 本課重點

```
三層的判斷邏輯：

  Deny：
    → 不可逆 + 高影響（一錯難回頭）
    → 機密相關（.env、secrets/）
    → 外部發布（git push、npm publish）

  Ask：
    → 可逆但有副作用（git commit 可以 revert，但已存在 history）
    → 啟動外部資源（docker run 可能消耗資源或開放通訊埠）
    → 你想保留「人類最後一關」的操作

  Allow：
    → 唯讀查詢（git status、git diff、grep）
    → 本地安全測試（npm run test、npm run lint）
    → 核心工作區的讀寫（src/** 是 AI 應該自由工作的地方）

設計原則：
  Ask 不是萬能的（全部 Ask = AI 每兩分鐘就打擾你）
  Deny 不是越多越好（把所有東西 Deny = AI 什麼都做不了）
  目標：讓 AI 在「安全工作區」裡自由工作，在「危險邊界」設關卡
```
