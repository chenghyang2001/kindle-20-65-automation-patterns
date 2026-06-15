---
name: analyze-patterns
description: 分析累積的操作日誌，提出 Skill 候選建議。
disable-model-invocation: true
---

# 模式分析

分析以下日誌，找出適合做成 Skill 的模式。

日誌檔案：!`tail -200 ~/.claude/logs/patterns.jsonl | jq -s .`

## 分析標準


- 偵測重複出現 3 次以上的指令序列
- 信心分數：（出現次數 / 總操作數）× 100
- 信心 ≥ 70% → 輸出為 Skill 候選
- 信心 40–70% → 持續觀察
- 信心 < 40% → 不列入候選


## 輸出格式

| 模式 | 出現次數 | 信心分數 | 建議 Skill 名稱 |
|------|---------|---------|----------------|
