# 第 2 課演練記錄：實作前檢查清單 — 動工前先審自己

> 對應文件：`code-中文/part7-workflows/skills/confidence-check/SKILL.md`

## 課程目標

學會用 5 項檢查清單（C1–C5）在動手前自我審查，
理解「通過 4/5 才能開工」的門檻設計，避免重複實作、架構違規、幻覺 API。

## 工作目錄

`code-中文/part7-workflows/demo/02-實作前檢查清單/`

---

## Step 1：安裝 confidence-check Skill

### 指令

```bash
# 將 Skill 複製到個人 Skills 目錄
cp -r code-中文/part7-workflows/skills/confidence-check \
      ~/.claude/skills/confidence-check
```

### 驗證

在 Claude Code 中輸入：

```
/confidence-check
```

### 預期結果

顯示 5 項檢查清單，等待填入任務名稱。

### 實際結果

（演練時填入）

---

## Step 2：對假設任務執行完整檢查

### 模擬任務

> 「幫我寫一個驗證信用卡格式的函式，放在 src/utils/ 下面。」

### 動作

在 Claude Code 中輸入：

```
/confidence-check 驗證信用卡格式的函式
```

### 演練任務

對 C1–C5 逐一回答 PASS / FAIL / SKIP，並說明理由：

| 項目 | 結果 | 理由 |
|------|------|------|
| C1：重複實作檢查 | | |
| C2：架構合規檢查 | | |
| C3：官方文件檢查 | | |
| C4：OSS 參考檢查 | | |
| C5：根本原因確認 | | |
| **總分** | / 5 | |

**結論**（可以開工 / 停下來調查）：

### 參考答案提示

<details>
<summary>展開提示</summary>

- C1：執行 `grep -r "credit_card\|validate_card" src/` — 如果 utils/validation.py 已存在類似函式，應判 FAIL
- C3：Luhn 演算法是公開規格，不需要外部 API；但若要用特定套件（如 stripe），需查該版本的 API
- C5：真實需求是「前端輸入驗證」還是「支付前後端驗證」？這會影響設計決策

</details>

### 實際結果

（演練時填入）

---

## Step 3：觀察 FAIL 項目如何影響決策

### 情境

假設 C1 判 FAIL（已有類似程式碼），討論：

1. 你會怎麼修改原有的函式而非重新實作？
2. 如果 C3 也 FAIL（文件未查），你會先做哪件事？

### 實際結果

（演練時填入）

---

## 本課重點

| 檢查項目 | 防止的問題 | 常見 FAIL 情境 |
|---------|-----------|---------------|
| C1 重複實作 | 相同邏輯出現兩套 | utils/ 深處藏有祖傳函式 |
| C2 架構合規 | 違反分層或命名慣例 | 直接把 DB 查詢塞進 Controller |
| C3 官方文件 | 幻覺 API 直接被寫進程式碼 | 用了不存在的套件方法 |
| C4 OSS 參考 | 重新造輪子 | 開源已有完整實作卻自己寫 |
| C5 根本原因 | 修錯地方 / 解錯問題 | 解決表象而非真正的 Bug |

> 門檻設計哲學：4/5（80%）而非 5/5（100%）— 因為 SKIP 是合理的，
> 但 2/5 以下代表你根本還沒準備好動手。
