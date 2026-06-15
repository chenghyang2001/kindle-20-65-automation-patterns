---
name: orchestrate
description: >
  依任務類型（feature/bugfix/refactor/security）
  選擇並執行對應的工作流。
  參數：feature|bugfix|refactor|security [任務名稱]
disable-model-invocation: true
argument-hint: "[feature|bugfix|refactor|security] [任務名稱]"
---

# Orchestrate：$ARGUMENTS

選擇並執行以下其中一個工作流。

## feature（新功能）

1. 定義需求與驗收標準
2. 實作前檢查（/confidence-check）
3. 建立設計文件（`docs/design/`）
4. 以 TDD 進行實作
5. 更新文件

## bugfix（Bug 修復）

1. 確認並記錄重現步驟
2. 找出根本原因（用 Grep + Read 調查）
3. 以最小範圍套用修復
4. 加入迴歸測試
5. 跑完整迴歸測試套件

## refactor（重構）

1. 變更前先確認測試覆蓋率
2. 用絞殺者無花果（Strangler Fig）模式漸進式遷移
3. 每一步都確認既有測試通過
4. 量測效能並用數字呈現改善幅度

## security（資安應變）

1. 以唯讀方式調查影響範圍（不使用 Write）
2. 比對 CVE 或弱點模式
3. 在隔離的 worktree 中套用修復
4. 由資安審查 agent 驗證
5. 在 release notes 中附上 CVE 編號

## custom

若參數不符合上述任何一種，請直接描述任務。
