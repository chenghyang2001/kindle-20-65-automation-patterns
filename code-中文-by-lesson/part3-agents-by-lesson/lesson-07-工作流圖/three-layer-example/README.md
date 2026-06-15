# 三層 Workflow 文件範例

這個目錄展示「同一個 reviewer pipeline」用三種方式記錄的完整範例。

## 三層結構

```
three-layer-example/
  ├── README.md              ← 自然語言層（你現在看的這個）
  ├── workflow.dot           ← DOT 圖視覺化層
  └── CLAUDE.md              ← 機器執行層
```

## 為什麼需要三層？

| 只用一種 | 問題 |
|---------|------|
| 只有 DOT 圖 | Claude 看不懂 dot，不會自動執行 |
| 只有 CLAUDE.md | 新成員不知道為何這樣排序、timeout 怎麼處理 |
| 只有自然語言 | Claude 執行時有歧義，spec FAIL 到底要不要跳 quality？|

## 這個 pipeline 為何這樣設計

**核心原則：正確性優先於品質**

spec-compliance 在前：不符規格的功能根本不用審品質。
fix 永遠回第一關：修改可能破壞之前通過的關卡，從頭驗才安全。
api-reviewer 在最後：API 設計建議只有在功能正確、品質過關、安全無虞後才有意義。
