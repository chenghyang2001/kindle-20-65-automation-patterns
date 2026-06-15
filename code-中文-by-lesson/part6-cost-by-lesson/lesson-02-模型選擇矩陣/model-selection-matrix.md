# 模型選擇矩陣

## 選對模型

讓模型能力對應任務複雜度，在不犧牲品質的前提下最佳化成本。

## 決策矩陣

| 任務類型 | 建議模型 | 理由 |
|-----------|-------------------|-----------|
| 程式碼庫搜尋與檔案探索 | haiku | 速度與成本優先 |
| 格式檢查與 pattern matching | haiku | 重複性、結構化任務 |
| Bug 修復與功能實作 | sonnet | 能力與成本兼顧 |
| 安全稽核 | sonnet | 準確度很重要 |
| 架構設計 | sonnet 或 opus | 需要複雜推理 |
| 生產環境關鍵生成 | inherit | 跟隨主對話設定 |

## Sub-agent 模型設定

### 逐 agent 指定模型

```markdown
---
name: file-explorer
description: 用於檔案搜尋與程式碼庫探索的高速 agent。
tools: Read, Grep, Glob
model: haiku
---
```

### 全域覆寫所有 sub-agent

```bash
export CLAUDE_CODE_SUBAGENT_MODEL=haiku
```

### 使用 `inherit`

```markdown
model: inherit
```

繼承呼叫方對話所使用的模型。
適用於需要與主 agent 相同品質水準的任務。

## 成本比較（約略值，每 100 萬 token）

| 模型 | 輸入 | 輸出 | 適合場景 |
|-------|-------|--------|----------|
| Claude Haiku | $0.80 | $4 | 大量、簡單的任務 |
| Claude Sonnet | $3 | $15 | 通用任務 |
| Claude Opus | $15 | $75 | 複雜推理、關鍵路徑 |

*價格為約略值。最新費率請參考 <https://anthropic.com/pricing> 。*

## 實務策略

1. 所有探索與搜尋類 sub-agent 預設用 `haiku`
2. 重視準確度的審查 agent 用 `sonnet`
3. `opus` 保留給架構決策或關鍵安全稽核
4. 當 sub-agent 品質必須與主對話一致時使用 `inherit`
