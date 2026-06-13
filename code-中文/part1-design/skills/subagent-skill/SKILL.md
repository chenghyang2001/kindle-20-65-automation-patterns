---
name: security-audit
description: 執行安全稽核。用於檢查程式碼是否有漏洞。
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
---

# 安全稽核

執行安全稽核：

1. 用 Grep 搜尋 `src/` 底下所有 TypeScript 檔案
2. 偵測以下 pattern：
   - SQL injection（查詢中使用字串串接）
   - XSS（直接指派給 innerHTML）
   - 硬編碼憑證（password/secret/key = "..."）
   - 使用 eval()
   - 危險的正規表達式（潛在 ReDoS）
3. 回報每個發現，附上檔案路徑與行號

## 輸出格式

每個問題回報：

- 檔案路徑:行號
- 問題類型（SQLi / XSS / 硬編碼憑證 / 其他）
- 嚴重程度（Critical / High / Medium / Low）
- 修復建議（1–2 句話）
