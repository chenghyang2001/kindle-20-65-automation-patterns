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

### 白名單分類表

| 類別 | 允許的操作 | 設計原因 |
|------|-----------|---------|
| git 安全操作（allow） | status / diff / log / branch / checkout / add | 唯讀或本地操作，不影響遠端 |
| npm 操作（allow） | `npm run *`、`npm install`、`npm ci` | 執行腳本和安裝依賴是日常開發需求 |
| 通用查詢（allow） | `* --version`、`* --help *` | 版本查詢和說明不改變任何狀態，零風險 |
| git 危險操作（deny） | push / reset --hard / rebase | 影響遠端或破壞 commit 歷史，難回復 |
| 網路下載（deny） | `curl *`、`wget *` | 可以從外網下載並執行惡意腳本 |
| 危險刪除（deny） | `rm -rf *` | 遞迴強制刪除，一條指令可清空整個目錄 |

### 回答

1. `Bash(git log *)` 裡的 `*` 代表什麼？

   答：`*` 代表「任意引數字串」——後面可以接 `--oneline`、`--graph`、`--since="1 week ago"` 等任何引數。規則只鎖定「指令名稱是 `git log`」，不限制引數內容。

2. 為什麼 `Bash(git push *)` 在 deny 清單？

   答：不只是怕推錯分支，更核心的原因是**不可逆性**：`git push --force` 可覆寫遠端 commit 歷史（影響所有協作者）；`git push origin main` 直接推 main 破壞保護規則。三鐵律之一：AI 不直接 push main。

3. `Bash(* --version)` 的作用？

   答：允許任何指令加上 `--version`（`node --version`、`python --version`、`git --version`）。CI 環境常見的「環境確認步驟」，`--version` 是唯讀操作，零副作用，所以可以用 `*` 開放所有指令。

### 實際結果

讀取 bash-patterns.json 確認：11 條 allow + 6 條 deny，覆蓋 git 安全操作、npm 執行、版本查詢、以及推送/下載/刪除禁令。

---

## Step 2：深入理解空格陷阱——單字邊界 vs 前綴比對

### 判斷練習

| 指令 | `Bash(ls *)` 的結果 | `Bash(ls*)` 的結果 |
|------|-----------------|-----------------|
| `ls -la` | ✅ 允許（`ls` + 引數 `-la`） | ✅ 允許 |
| `ls /tmp` | ✅ 允許（`ls` + 引數 `/tmp`） | ✅ 允許 |
| `lsof -i :8080` | ❌ 拒絕（`lsof` ≠ `ls`） | ✅ 允許 ⚠️ |
| `lsattr -a` | ❌ 拒絕（`lsattr` ≠ `ls`） | ✅ 允許 ⚠️ |
| `ls`（不加引數） | ❌ 拒絕（規則要求空格後有引數） | ✅ 允許 |

注意：`ls`（不加引數）被 `Bash(ls *)` 拒絕，因為規則要求空格後需有引數內容。若要同時允許有/無引數，需額外加 `"Bash(ls)"`。

### 思考問題

1. 少打一個空格 `Bash(ls*)` 的最壞情況：

   答：`lsof -i -P -n` 可以列出所有開啟的網路連線、監聽的通訊埠、對應的程序 PID。攻擊者（或被 Prompt Injection 控制的 AI）可以用它繪製整個系統的網路拓撲圖，找到可攻擊的服務入口。一個空格差異，從「列目錄」變成「網路偵察工具」。

2. 這個空格錯誤在 code review 容易被漏掉嗎？

   答：**非常容易**。`ls *` 和 `ls*` 視覺差異極小，且「允許 ls 相關指令」的意圖完全合理。大多數 reviewer 聚焦在邏輯層面，不會逐字檢查有沒有空格。

3. 其他以常見指令開頭但實際上危險的指令：

   | 前綴 | 危險的衍生指令 | 危險程度 |
   |------|------------|---------|
   | `git*` | `git-secrets`（掃描機密）、`gitk`（GUI 歷史瀏覽器） | 中 |
   | `npm*` | `npm-cli-login`（改 npm 帳號認證） | 中 |
   | `python*` | `python-dotenv`（讀取 .env）、`pythonw`（無終端機執行） | 高 |
   | `ps*` | `psql`（PostgreSQL 客戶端，直接操作資料庫） | 極高 |
   | `curl*` | `curlftpfs`（FTP 掛載，可存取遠端系統） | 高 |

### 實際結果

理解空格決定比對模式：有空格 = 單字邊界（安全）；無空格 = 前綴比對（危險）。`lsof` 是最典型的空格陷阱受害者。

---

## Step 3：比對兩種寫法 + 設計練習

### 兩種模式比較

| 比較 | `Bash(git status)` | `Bash(git diff *)` |
|------|------------------|------------------|
| 匹配的指令 | 只有 `git status`（完全匹配） | `git diff`、`git diff HEAD`、`git diff --stat` |
| 使用萬用字元的原因 | 這個指令不需要引數 | 需要靈活指定比對範圍 |
| 安全性風險 | 無（完全固定） | 低（引數不會改變指令的根本行為） |

### 設計練習

| 想允許的操作 | 你的 Bash 規則 | 理由 |
|------------|-------------|------|
| 只允許 `npm run test` | `"Bash(npm run test)"` | 完全固定，不加萬用字元 |
| 允許 `npm run test` 和所有 test 開頭的腳本 | `"Bash(npm run test *)"` | `test 後加空格+`*`，只允許 test 系列 |
| 只允許 `python --version` | `"Bash(python --version)"` | 完全固定，零副作用 |
| 允許 `python` 執行任何腳本 | `"Bash(python *)"` | 空格+`*` 只允許 python 指令，不含 `pythonw`、`python3-config` 等 |

### 實際結果

設計四條 Bash 規則：固定指令不加萬用字元，需要引數才加「空格+*」，永遠不用前綴比對。

---

## Step 4：測試你對空格陷阱的理解

### 快問快答

1. `"Bash(npm *)"` — 允許所有 npm 開頭的指令

   答：⚠️ **危險**：允許 `npm publish`（發佈套件）、`npm adduser`（改帳號認證）、`npm deprecate`（棄用套件）等危險操作。

2. `"Bash(npm run *)"` — 允許 npm run + 任何引數

   答：✅ **安全**：只允許執行 package.json 裡定義的腳本，不能呼叫 npm 的其他子指令。

3. `"Bash(python *)"` — 允許 python + 任何引數

   答：⚠️ **謹慎**：允許 `python -c "import os; os.system(...)"` 執行任意系統指令（Python 是「指令執行的跳板」）。若確定只要跑腳本，建議限縮為 `"Bash(python *.py)"`。

4. `"Bash(docker *)"` — 允許所有 docker 指令

   答：🔴 **危險**：允許 `docker run --privileged`（可逃逸 container 存取宿主機）；`docker exec`（可進入任何 container）。

5. `"Bash(git status)"` — 只允許 git status（完全匹配）

   答：✅ **最安全**：完全固定，唯讀，零副作用。

6. `"Bash(git *)"` — 允許所有 git 指令

   答：⚠️ **危險**：`git push *` 已在 deny 清單保護，但 `git config --global`（可改全域 git 設定）未被 deny 清單封鎖，是潛在漏洞。

### 實際結果

分析六條設定：npm run * git status 最安全；npm*/ docker */ ython* 都不同程度的危險。

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

code review 要加的 checklist：
  □ Bash 規則有沒有空格？（有空格 = 安全，無空格 = 危險）
  □ python * / node * 這類「跳板指令」是否真的必要？
  □ docker * 是否已有對應的 deny 限制高風險子指令？
```
