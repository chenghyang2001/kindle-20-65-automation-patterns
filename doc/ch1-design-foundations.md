# 第1章 Design Foundations — 系統設計基礎

> Claude Code in Production | Yosuke Morikawa | Patterns 1–10

---

## 章節概覽

本章建立 Claude Code 的三層記憶架構，讓 AI 不再「失憶」。核心思想：
**把知識分層存放，按穩定性決定放哪裡**。

---

## 核心模式

### Pattern 1–3：CLAUDE.md 三層結構

```
全域 ~/.claude/CLAUDE.md        ← 所有專案共用（技術棧、全域規則）
專案 ./CLAUDE.md                 ← 當前專案架構、編碼慣例
子目錄 ./packages/*/CLAUDE.md   ← monorepo 各套件的局部規則
```

**關鍵設計：穩定內容放頂部（prompt cache 命中率高），揮發內容放底部。**

```markdown
<!-- CLAUDE.md 推薦排版 -->
## 穩定資訊（置頂）
- 專案概述、技術棧、編碼慣例、固定參考文件

## 揮發資訊（置底）
- 當前工作狀態、最近變更、TODO 清單
```

---

### Pattern 4–5：Rules 系統（路徑過濾）

```yaml
---
paths:
  - "src/api/**/*.ts"
---
# API Development Rules
- 所有端點必須包含輸入驗證
- 使用 `ApiError` 型別
- 必加 OpenAPI 註解
```

好處：只有在編輯 `src/api/` 下的 TypeScript 檔案時，這條規則才生效。**避免無關規則污染 context。**

---

### Pattern 6–8：Skills 設計三原則

#### ① Good Description（最重要）
```yaml
---
name: deploy
description: >
  Deploy to production. Must be invoked explicitly with the /deploy command.
  Use for: production releases, emergency deployments.
disable-model-invocation: true
---
```
- `description` 必須說清楚「何時用」「何時不用」
- 壞例子：`description: Deploy things`（太模糊 → AI 亂觸發）
- 好例子：加上觸發條件 + 排除情境

#### ② Dynamic Context（`!` 指令注入）
```yaml
name: pr-summary
context: fork
---
- PR diff: !`gh pr diff`
- 最新提交: !`git log origin/main..HEAD --oneline`
```
Skill 啟動時自動執行指令並把輸出注入 context，不用手動貼。

#### ③ Invocation Control
- `disable-model-invocation: true`：Skill 只執行指令不呼叫 LLM（純 shell 流程）
- `context: fork`：隔離 context，長時間作業不污染主對話

---

### Pattern 9–10：Compact Instructions + PreCompact Hook

```json
{
  "hooks": {
    "PreCompact": [{
      "matcher": "auto",
      "hooks": [{"type": "command", "command": "bash .claude/hooks/save-session-state.sh"}]
    }]
  }
}
```

壓縮前自動存狀態：

```bash
cat > ".claude/session-state.md" << EOF
# Session State (saved: ${DATE})
## Branch: $(git branch --show-current)
## Uncommitted: $(git diff --name-only)
## Recent Commits: $(git log --oneline -5)
EOF
```

CLAUDE.md 底部加入：
```markdown
## Compact Instructions
壓縮時一定保留：所有已修改檔案的完整路徑、執行指令的成功/失敗狀態、未完成任務。
```

---

## 如何套用到我的工作流

| 目前問題 | 本章解法 |
|---------|---------|
| 每個 session 都要重新解釋環境 | 全域 `~/.claude/CLAUDE.md` + `@instructions/` 模組化 |
| Skill 觸發錯誤 | 改寫 `description` 加上觸發 + 排除條件 |
| 長作業污染主對話 | Skill 加 `context: fork` |
| Session 結束後忘記進度 | PreCompact Hook + compact-rules.md |

---

## 最值得馬上借鑑

1. **`skills/good-description/` 重寫現有 Skills 的 description**
   - 用格式：「觸發：X 情境 → 用。排除：Y 情境 → 不用」
   - 立即效果：AI 停止亂觸發 Skill

2. **CLAUDE.md 穩定/揮發分區**
   - 把常改的 TODO、當日工作狀態搬到底部
   - 頂部只放技術棧、全域規則 → prompt cache 命中率大幅提升

---

## Sample Code 位置

```
code/part1-design/
├── claude-md/compact-instructions.md    ← PreCompact 完整範例
├── claude-md/import-example/CLAUDE.md  ← @import 模組化範例
├── claude-md/monorepo-example/          ← monorepo 三層 CLAUDE.md
├── rules/coding-conventions.md          ← 路徑過濾規則
└── skills/
    ├── good-description/SKILL.md        ← 好 description 示範
    ├── dynamic-context/SKILL.md         ← !指令注入示範
    └── invocation-control/deploy.SKILL.md ← disable-model-invocation 示範
```
