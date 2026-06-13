# 第 2 課演練記錄：Bash 指令白名單的空格陷阱

> 對應文件：`code-中文/part5-security/permissions/bash-patterns.json`

## 課程目標

理解 Bash 指令模式匹配中「一個空格」如何決定資安生死，
學會正確寫法讓 `ls *` 允許列檔但拒絕 `lsof`（網路掃描工具），
掌握設計安全 Bash 白名單的核心原則。

## 工作目錄

`code-中文/part5-security/demo/02-Bash空格陷阱/`

---

## Step 1：閱讀 bash-patterns.json，分析白名單設計

### 閱讀任務

打開 `permissions/bash-patterns.json`，填入：

| 類別 | 允許的操作 | 設計原因 |
|------|-----------|---------|
| git 安全操作（allow） | git status、git diff \*... | 唯讀 / 本地操作 |
| npm 操作（allow） | | |
| 通用查詢（allow） | | |
| git 危險操作（deny） | | |
| 網路下載（deny） | | |
| 危險刪除（deny） | | |

回答：

1. `Bash(git log *)` 裡的 `*` 代表什麼？後面可以接什麼引數？

   答：

2. 為什麼 `Bash(git push *)` 在 deny 清單？只是因為怕推錯嗎？

   答：

3. `Bash(* --version)` 這個規則的作用是什麼？什麼情況下有用？

   答：

### 實際結果

（演練時填入）

---

## Step 2：深入理解空格陷阱——單字邊界 vs 前綴比對

### 關鍵概念

```
寫法 A：Bash(ls *)        ← ls 後面有空格再接 *
         系統解析為：指令名稱 = "ls"，引數 = 任意字串
         允許：ls -la、ls /tmp、ls -lh src/
         拒絕：lsof（因為 "lsof" 不是以 "ls " 開頭）

寫法 B：Bash(ls*)         ← ls 後面直接接 * 沒有空格
         系統解析為：以 "ls" 開頭的任何字串（前綴比對）
         允許：ls、ls -la、lsof、lsattr、lsblk...
         ★ lsof = List Open Files，可掃描網路通訊埠，駭客常用工具
```

### 判斷練習

以下哪些指令會被 `Bash(ls *)` **允許**？哪些會被**拒絕**？

| 指令 | `Bash(ls *)` 的結果 | `Bash(ls*)` 的結果 |
|------|-----------------|-----------------|
| `ls -la` | | |
| `ls /tmp` | | |
| `lsof -i :8080` | | |
| `lsattr -a` | | |
| `ls` （不加引數） | | |

### 思考問題

1. 一個工程師原本的用意是「讓 AI 能列出目錄裡的檔案」，
   少打了一個空格，寫成 `Bash(ls*)`。最壞的情況是什麼？

   答：

2. 這個空格錯誤在 code review 時很容易被漏掉嗎？為什麼？

   答：

3. 除了 `lsof`，還有哪些以常見指令開頭但實際上很危險的指令？
   （提示：想想 `git`、`npm`、`python` 開頭的危險組合）

   答：

### 實際結果

（演練時填入）

---

## Step 3：比較 bash-patterns.json 裡的兩個寫法

### 觀察

在 bash-patterns.json 裡找出以下兩種模式，分析差異：

1. `Bash(git status)` — 沒有萬用字元
2. `Bash(git diff *)` — 有萬用字元

| 比較 | `Bash(git status)` | `Bash(git diff *)` |
|------|------------------|------------------|
| 匹配的指令 | 只有 `git status`（完全匹配） | `git diff`、`git diff HEAD`、`git diff --stat` |
| 使用萬用字元的原因 | 這個指令不需要引數 | 需要靈活指定比對範圍 |
| 安全性風險 | 無（完全固定） | 低（引數不會改變指令的根本行為） |

### 練習

設計以下操作的 Bash 允許規則，思考每個要不要加空格和萬用字元：

| 想允許的操作 | 你的 Bash 規則 | 理由 |
|------------|-------------|------|
| 只允許 `npm run test`（不允許 `npm run test:e2e` 或其他） | | |
| 允許 `npm run test` 和所有以 test 開頭的腳本 | | |
| 只允許 `python --version`（版本查詢） | | |
| 允許 `python` 執行任何腳本 | | |

### 實際結果

（演練時填入）

---

## Step 4：測試你對空格陷阱的理解

### 快問快答

以下設定是否安全？填入「安全」或「危險（原因）」：

1. `"Bash(npm *)"` — 允許所有 npm 開頭的指令

   答：

2. `"Bash(npm run *)"` — 允許 npm run + 任何引數

   答：

3. `"Bash(python *)"` — 允許 python + 任何引數

   答：

4. `"Bash(docker *)"` — 允許所有 docker 指令

   答：

5. `"Bash(git status)"` — 只允許 git status（完全匹配）

   答：

6. `"Bash(git *)"` — 允許所有 git 指令

   答：

### 實際結果

（演練時填入）

---

## 本課重點

```
空格陷阱的本質：
  有空格：Bash(ls *)  → 單字邊界比對 → "ls" 是獨立指令名稱
  無空格：Bash(ls*)   → 前綴比對    → 任何以 "ls" 開頭都通過

lsof 危險在哪裡：
  lsof = List Open Files
  可以列出所有開啟的檔案和網路通訊埠
  駭客用它做 port scanning，探測系統有哪些服務在運行

安全白名單設計三原則：
  1. 完全固定的指令：不加萬用字元（如 Bash(git status)）
  2. 需要引數但根指令安全：加「空格+萬用字元」（如 Bash(git diff *)）
  3. 永遠避免「前綴萬用字元」（如 Bash(git*) 會命中 git-secrets、gitk 等）

高風險的前綴：
  Bash(curl*)  → 可能命中 curlftpfs（FTP 掛載工具）
  Bash(rm*)    → 可能命中 rmdir（大範圍刪除）
  Bash(ps*)    → 可能命中 psql（直接操作資料庫）
  Bash(ls*)    → 可能命中 lsof（網路掃描）
```
