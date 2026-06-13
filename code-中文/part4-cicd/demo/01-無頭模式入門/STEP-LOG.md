# 第 1 課演練記錄：無頭模式入門

> 對應文件：`code-中文/part4-cicd/scripts/basic-ci.sh`

## 課程目標

理解 `claude -p` 如何讓 AI 從「對話助理」變成「沉默的流水線員工」，
掌握三個最重要的 CI 引數：`--allowedTools`、`--max-turns`，
實際執行腳本觀察 exit code 的運作。

## 工作目錄

`code-中文/part4-cicd/demo/01-無頭模式入門/`

---

## Step 1：閱讀 basic-ci.sh，理解三種模式

### 閱讀任務

打開 `scripts/basic-ci.sh`，填入三種模式的差異：

| 模式 | 如何傳入內容 | 使用的引數 |
|------|------------|-----------|
| 模式 1 | | |
| 模式 2 | | |
| 模式 3 | | |

回答：

1. `< /dev/null` 在模式 1 和 3 的作用是什麼？

   答：

2. `--max-turns 5` 和 `--max-turns 3` 分別限制了什麼？

   答：

3. 模式 2 用 `cat ... |` 傳入檔案，和用 `--allowedTools "Read"` 讀取有什麼差別？

   答：

### 實際結果

（演練時填入）

---

## Step 2：執行模式 1，觀察無頭模式的輸出

### 指令

從專案根目錄執行：

```bash
cd c:/Users/user/workspace/kindle-20-65-automation-patterns

claude -p "What is this project about? Look at the README or CLAUDE.md if available, otherwise infer from the directory structure. Answer in exactly 2 sentences." \
  --allowedTools "Read,Glob" \
  --max-turns 5 < /dev/null
```

### 觀察重點

1. 輸出是直接的答案，還是帶有「好的，我來為您分析」這類前言？

   答：

2. 指令執行完後，shell 有等待你按 Enter 嗎？

   答：

3. 執行完後查看 exit code：

```bash
echo "Exit code: $?"
```

   結果：

### 實際結果

（演練時填入）

---

## Step 3：測試防爆機制 — 限制工具

### 情境

如果 AI 在沒有授權的情況下試圖使用不在白名單裡的工具，會發生什麼？

### 指令

```bash
claude -p "List all Python files in this project and show me their content." \
  --allowedTools "Glob" \
  --max-turns 3 < /dev/null
echo "Exit code: $?"
```

### 觀察

1. AI 只有 `Glob`（找檔名）權限，沒有 `Read`（讀內容）權限，它怎麼處理這個限制？
2. Exit code 是 0 還是非零？

### 實際結果

（演練時填入）

---

## Step 4：理解三道防爆機制

### 填表練習

| 引數 | 防止什麼 | 觸發條件 |
|------|---------|---------|
| `--allowedTools "Glob"` | | |
| `--max-turns 20` | | |
| `--max-budget-usd 2` | | |

### 思考問題

如果 CI Pipeline 沒有設置任何這三個引數，最壞的情況會是什麼？

答：

### 實際結果

（演練時填入）

---

## 本課重點

```
claude -p 的核心行為：
  ✅ 背景執行，不等待使用者輸入
  ✅ 結果印到 stdout（可被 Pipeline 捕捉）
  ✅ 成功 = exit 0，失敗 = exit 非零
  ✅ 接受 stdin（用管線或 < /dev/null）

三道防爆衝引數（缺一不可）：
  --allowedTools   → 白名單（防止問東問西）
  --max-turns      → 回合上限（防止無限迴圈）
  --max-budget-usd → 費用上限（防止百萬帳單）
```
