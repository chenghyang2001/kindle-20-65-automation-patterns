# 第 7 課演練記錄：Plugin 封裝 — 分享整套配置給團隊

> 對應文件：
>
>
> - `code-中文/part7-workflows/plugin-example/.claude-plugin/plugin.json`
> - `code-中文/part7-workflows/plugin-example/hooks/hooks.json`
> - `code-中文/part7-workflows/scripts/install-skill.sh`

## 課程目標

把前六課建立的 Skills + Hooks 打包成一個可分享的 Plugin，
理解 Plugin 的目錄結構與 manifest 格式，
學會用 install-skill.sh 從 GitHub 安裝他人的 Skill，
消滅「只有你知道怎麼設定」的部落知識。

## 工作目錄

`code-中文/part7-workflows/demo/07-Plugin封裝/`

---

## Step 1：理解 Plugin 目錄結構

### 閱讀任務

打開 `plugin-example/` 資料夾，觀察結構：

```
plugin-example/
├── .claude-plugin/
│   └── plugin.json       ← Plugin manifest（描述 name / version / author）
└── hooks/
    └── hooks.json        ← 宣告這個 Plugin 附帶哪些 Hook
```

對照 `plugin.json`，填入：

| 欄位 | 值 |
|------|-----|
| name | |
| version | |
| description | |
| license | |

對照 `hooks.json`，回答：

1. 這個 Plugin 的 Hook 在哪個時機點觸發？
2. matcher 是什麼（會攔截哪些工具操作）？
3. Hook 執行的腳本路徑用了什麼環境變數？（提示：`${...}`）

### 實際結果

（演練時填入）

---

## Step 2：建立自己的 Plugin（mini 版）

### 目標

把前幾課的 `confidence-check` + `orchestrate` 兩個 Skill，
加上 `observe-pattern` Hook，打包成一個 Plugin。

### 建立目錄結構

```bash
mkdir -p my-workflow-plugin/.claude-plugin
mkdir -p my-workflow-plugin/skills/confidence-check
mkdir -p my-workflow-plugin/skills/orchestrate
mkdir -p my-workflow-plugin/hooks

# 複製 Skills
cp code-中文/part7-workflows/skills/confidence-check/SKILL.md \
   my-workflow-plugin/skills/confidence-check/
cp code-中文/part7-workflows/skills/orchestrate/SKILL.md \
   my-workflow-plugin/skills/orchestrate/

# 複製 Hook
cp code-中文/part7-workflows/hooks/observe-pattern.sh \
   my-workflow-plugin/hooks/
```

### 建立 manifest（plugin.json）

在 `my-workflow-plugin/.claude-plugin/plugin.json` 建立：

```json
{
  "name": "my-workflow-plugin",
  "version": "1.0.0",
  "description": "7 階段工作流：confidence-check + orchestrate + 觀察 Hook",
  "author": {
    "name": "（你的名字）"
  },
  "license": "MIT"
}
```

### 建立 hooks manifest（hooks.json）

在 `my-workflow-plugin/hooks/hooks.json` 建立：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/observe-pattern.sh"
          }
        ]
      }
    ]
  }
}
```

### 實際結果

（演練時填入）

---

## Step 3：用 install-skill.sh 安裝（模擬）

### 閱讀任務

打開 `scripts/install-skill.sh`，回答：

1. 這個腳本需要幾個參數？分別是什麼？

   答：

2. `SCOPE` 參數的兩個選項（project / personal）分別把 Skill 安裝到哪裡？

   | SCOPE | 安裝路徑 |
   |-------|---------|
   | project | |
   | personal | |

3. 腳本如何避免重複安裝（已存在時怎麼處理）？

   答：

### 模擬安裝指令

```bash
# 模擬從 GitHub 安裝（用本地路徑示範）
bash code-中文/part7-workflows/scripts/install-skill.sh \
     confidence-check \
     https://github.com/example/skills \
     personal
```

### 實際結果

（演練時填入，若無 GitHub repo 可跳過實際執行，只回答問題）

---

## Step 4：思考 Plugin 生態系統

### 討論問題

1. 如果你的團隊用同一套 Plugin，「部落知識」會消失的原因是什麼？

   答：

2. Plugin 版本號（1.0.0）的意義是什麼？當你修改了 Hook 行為後，應該升到幾版？

   答：

3. `${CLAUDE_PLUGIN_ROOT}` 這個環境變數的設計，解決了什麼硬編碼路徑的問題？

   答：

### 實際結果

（演練時填入）

---

## 本課重點

```
Plugin 的本質：
把 Skills + Hooks + 設定 打包成一個有名稱、有版本的可安裝單元。
讓「我個人精心調教的工作流」→「整個團隊共用的標準配置」。
```

| 元件 | 功能 |
|------|------|
| `plugin.json` | Plugin 身分證（name / version / author） |
| `hooks.json` | 宣告 Plugin 附帶的 Hook 設定 |
| `skills/` | Plugin 內附的 Skill 集合 |
| `install-skill.sh` | 從 GitHub 安裝單一 Skill 的工具 |
| `${CLAUDE_PLUGIN_ROOT}` | 讓 Hook 路徑不硬編碼，跨機器可攜 |

---

## 七堂課總結

| 課次 | 主題 | 核心工具 | 難度 |
|------|------|---------|------|
| 01 | 幻覺偵測 | hallucination-detection.md | ★☆☆ |
| 02 | 實作前檢查清單 | /confidence-check | ★★☆ |
| 03 | 動態編排 | /orchestrate | ★★☆ |
| 04 | 七階段工作流 + Checkpoint | /dev-workflow + Esc+Esc | ★★★ |
| 05 | 多 Agent Worktree | cascade-start.sh | ★★★ |
| 06 | 觀察 Hook + 自我進化 | observe-pattern.sh + /analyze-patterns | ★★★★ |
| 07 | Plugin 封裝 | plugin.json + install-skill.sh | ★★★★★ |
