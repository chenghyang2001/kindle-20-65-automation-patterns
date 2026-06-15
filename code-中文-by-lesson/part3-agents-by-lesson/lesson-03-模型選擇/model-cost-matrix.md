# Sub-agent 模型選擇矩陣

依任務類型選用合適的模型，以最佳化成本。

## 模型選擇表

| 任務類型 | 建議模型 | 理由 |
|-----------|-------------------|--------|
| 檔案探索與搜尋 | haiku | 速度與成本優先 |
| 程式碼審查（格式檢查） | haiku | 以 pattern matching 為主 |
| Bug 修復與實作 | sonnet | 能力均衡 |
| 安全稽核 | sonnet | 需要高準確度 |
| 架構設計 | sonnet 或 opus | 需要複雜推理 |
| 大規模重構 | inherit | 沿用主對話的設定 |

## 範例：Haiku 代理設定

```markdown
---
name: file-explorer
description: >
  專精於檔案搜尋、列表與內容檢視的高速代理。
  程式碼庫探索任務時主動使用。
tools: Read, Grep, Glob
model: haiku
---

作為檔案探索專家，有效率地收集並回報
被要求的資訊。不做任何修改。
只回傳你找到的內容。
```

## 一次設定所有 Sub-agent 的模型

```bash
# 把所有 sub-agent 都設為 Haiku
export CLAUDE_CODE_SUBAGENT_MODEL=haiku
```

## 何時使用 `inherit`

`model: inherit` 會繼承主對話的模型設定。
適用於需要正式環境品質的任務，或希望 sub-agent
跟隨主對話模型設定的情況。

## 注意事項

模型別名（例如 `haiku`）會在執行時解析為最新支援的模型。
直接指定模型 ID 會固定版本 — 大多數情況請使用別名。
