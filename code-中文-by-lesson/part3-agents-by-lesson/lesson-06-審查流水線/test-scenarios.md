# code-reviewer 測試情境

## TC-01: 安全性問題偵測

輸入：用 SQL 字串串接組建查詢的程式碼
預期：標記出 SQL injection 並附上修正建議
通過標準：回應中包含「SQL injection」

## TC-02: 不過度標記良好的程式碼

輸入：具備標準錯誤處理的程式碼
預期：不回報任何 Critical 等級問題
通過標準：回應中不包含「Critical」

## TC-03: 優先級分類

輸入：含有多個問題的程式碼
預期：問題被分類為 Critical / Warning / Suggestion
通過標準：回應中至少包含一個分類標籤
