# 第 1 課演練記錄：認識內建 Sub-agents

> 對應文件：`docs/builtin-agents-reference.md`
> 主題：Claude Code 開箱即有哪些 agent，各自的模型和工具限制

---

## 核心觀念

Sub-agent 最大特色是**隔離 context**：每個 agent 有獨立的對話窗口，不污染主對話。代價是多一次 API 呼叫。

---

## Step 1：六個內建 Agent 一覽表

**命令：**

```bash
cat code-中文/part3-agents/docs/builtin-agents-reference.md
# 或在 Claude Code 互動模式：/agents
```

**實際驗證：** ✅

| 內建 Agent | 模型 | 工具限制 | 典型用途 |
|-----------|------|---------|---------|
| Explore | **Haiku** | **唯讀** | 程式碼庫探索與搜尋 |
| Plan | **Inherit** | **唯讀** | Plan 模式下的研究 |
| General-purpose | **Inherit** | **所有工具** | 複雜多步驟任務 |
| Bash | **Inherit** | **僅 Bash** | 獨立終端機指令執行 |
| statusline-setup | Sonnet | Read/Write | /statusline 設定 |
| Claude Code Guide | Haiku | Read | Claude Code 功能問答 |

**Explore 為什麼用 Haiku**：只做搜尋，不需推理，用最便宜的模型省 60-80% 成本。

---

## Step 2：「Sub-agent 不可巢狀」— 後果分析

三種情境哪個會失敗：

| 情境 | 結構 | 結果 |
|------|------|------|
| A：主 → Explore（1層）| 正常呼叫 | ✅ 正常 |
| **B：主 → General-purpose → Explore（2層）** | **巢狀** | ❌ **失敗** |
| C：主 → Explore；主 → Plan（各自 1 層）| 循序 | ✅ 正常 |

**關鍵區別**：B 是 General-purpose **在執行中**再派出 Explore（巢狀）；C 是主對話**先後呼叫**兩個 agent（循序）。

**遇到 B 情境的解法**：改用 Skills（agent context 內可呼叫 skill），或讓主對話接收 General-purpose 結果後再呼叫 Explore。

---

## Step 3：Task(AgentName) 格式 + 三任務選型

**問題 1：`Task(Explore)` 和 Permission Model 的關係**

Part 5 deny 格式：`工具名稱(pattern)`，例如 `Bash(rm *)` = 封鎖含 `rm` 的 Bash 指令。
`Task(Explore)` = 封鎖「派遣 Explore agent」這個 Task 工具呼叫。
**Permission Model 不只管工具，也管 agent 的生成本身。**

**問題 2：三個任務選哪個 agent**

| 任務 | 選哪個 | 理由 |
|------|--------|------|
| 搜尋 `.py` 中 `import os` 行號 | **Explore** | 純讀取搜尋，Haiku 夠用，隔離 context |
| 分析架構 + 寫 README | **General-purpose** | 需要讀（分析）+ 寫（README）|
| 執行 `pytest` 回傳退出碼 | **Bash** | 只跑一個指令，最輕量 |

**選擇邏輯**：只需讀/搜尋 → Explore（省錢）；讀 + 寫 → General-purpose；只跑指令 → Bash。

---

## Step 4：設計 CI 環境禁用規則

**情境**：禁止 agent 自動搜尋程式碼，但允許執行 bash 指令。

**答案：**

```json
{
  "permissions": {
    "deny": [
      "Task(Explore)",
      "Task(general-purpose)"
    ]
  }
}
```

**注意**：`Explore`（大寫）、`general-purpose`（全小寫含連字號），必須和 Claude Code 內部 agent ID 完全一致。Bash agent 不需列入 deny（允許 = 不寫）。

**CLI 等效：**

```bash
claude --disallowedTools "Task(Explore)" --disallowedTools "Task(general-purpose)"
```

**產出物：** `docs/builtin-agents-reference.md`（分析對象）
