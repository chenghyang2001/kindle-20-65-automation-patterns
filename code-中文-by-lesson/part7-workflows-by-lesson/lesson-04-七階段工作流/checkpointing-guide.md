# Checkpoint（檢查點）指南

## 基本操作

```text
# 開啟 rewind 選單
Esc + Esc  或  /rewind

# 選單中可用的動作
1. Restore code and conversation（還原程式碼與對話）
   → 將程式碼與對話歷史一併還原到該時間點
2. Restore conversation（還原對話）
   → 只回退對話歷史；保留程式碼變更
3. Restore code（還原程式碼）
   → 只還原檔案變更；對話繼續進行
4. Summarize from here（從此處開始摘要）
   → 把這個時間點之後的訊息壓縮成摘要，釋放 context
5. Never mind（取消）
   → 取消並關閉選單
```

## 在高風險變更前建立檢查點

```markdown
# 開始大型變更前的提示詞範例

請將目前狀態記錄為檢查點。
接下來我會嘗試以下重構。
如果失敗，我會用 Esc+Esc 回到這個時間點。

[預計變更]
把 src/auth/ 底下以類別為基礎的程式碼
改寫為以函式為基礎的程式碼。
```

## 使用 Summarize（摘要）

```markdown
# 長時間除錯後釋放 context

在一場冗長的除錯之後：
1. 開啟 /rewind
2. 選取除錯開始的那則訊息
3. 選擇「Summarize from here」
4. 輸入摘要指示：
   「只記錄 bug 的根本原因與最終套用的修復方式。」
```

## 運作原理

- Checkpoint 只追蹤 Claude Code 檔案編輯工具（Write/Edit）所做的變更
- 每次使用者送出提示詞時會自動建立快照
- 快照在 session 結束後保留 30 天（截至 2026 年 2 月）

## 注意事項

- 透過 bash 指令（rm、mv、cp 等）所做的檔案變更不會被追蹤
- 會修改大量檔案的腳本，請用 Git commit 手動建立檢查點
- Checkpoint 是 Git 的輔助工具，不是替代品
