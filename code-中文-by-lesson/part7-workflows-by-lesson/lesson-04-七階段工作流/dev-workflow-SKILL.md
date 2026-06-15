---
name: dev-workflow
description: >
  啟動 7 階段開發工作流。
  作為新功能、Bug 修復與重構的起點使用。
disable-model-invocation: true
---

# 7 階段開發工作流

**任務**：$ARGUMENTS

## 階段 1：腦力激盪


- 用 1–3 句話定義任務
- 明確寫出完成標準
- 列出不在範圍內的事項


## 階段 2：Worktree

- `git worktree add ../work-$ARGUMENTS-$(date +%s) -b feature/$ARGUMENTS`
  （任務名稱不可含空格。例如：`user-auth` 可以，`user auth` 不行）
- 所有工作都在這個 worktree 中進行


## 階段 3：規劃（執行 /confidence-check）

- 完成實作前檢查清單（見 P59）

- 達到 ≥ 90% 才能進入下一階段

## 階段 4：Sub-agent


- 把探索任務委派給 Explore agent


## 階段 5：TDD

- 先寫測試，再實作


## 階段 6：審查

- 執行 `/review` 並解決所有被提出的問題

## 階段 7：完成

- Commit、移除 worktree、執行 `/session-end`
