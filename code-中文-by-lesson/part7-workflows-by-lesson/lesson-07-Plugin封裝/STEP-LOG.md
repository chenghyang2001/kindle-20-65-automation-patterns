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
| name | `my-team-plugin` |
| version | `1.0.0` |
| description | `團隊共用的 Skills、Hooks 與 Agents` |
| license | `MIT` |

對照 `hooks.json`，回答：

1. 這個 Plugin 的 Hook 在哪個時機點觸發？

   **PostToolUse**（工具執行完成後觸發）

2. matcher 是什麼（會攔截哪些工具操作）？

   **`Write|Edit`**（只攔截 Write 和 Edit 工具）
   和第 6 課的 `.*`（全部工具）不同，這個 Plugin 只在「寫入/修改檔案後」執行 lint，不是所有操作都記錄。

3. Hook 執行的腳本路徑用了什麼環境變數？

   **`${CLAUDE_PLUGIN_ROOT}`**
   完整路徑：`${CLAUDE_PLUGIN_ROOT}/scripts/lint.sh`

### 實際結果

Plugin 的結構分成兩層：

- `.claude-plugin/plugin.json`：Plugin 的「身分證」（名稱/版本/作者/授權）
- `hooks/hooks.json`：Plugin 的「行為宣告」（在哪個時機、攔哪些工具、跑哪個腳本）
- `${CLAUDE_PLUGIN_ROOT}` 讓 Hook 路徑不綁定機器，跨機器可攜。

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
    "name": "Peter Yang"
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

`${CLAUDE_PLUGIN_ROOT}` 是這步的核心設計決策：
如果寫成 `${HOME}/.claude/plugins/my-workflow-plugin/hooks/observe-pattern.sh`，
換到另一台機器或另一個使用者就會路徑錯誤。
`${CLAUDE_PLUGIN_ROOT}` 讓 Claude Code 在載入 Plugin 時動態注入實際路徑，
和 Python 裡用 `Path.home()` 不寫 `C:/Users/peter/` 是完全相同的設計哲學。

```
公司機：${CLAUDE_PLUGIN_ROOT} = /Users/peter/.claude/plugins/my-workflow-plugin
家用機：${CLAUDE_PLUGIN_ROOT} = /home/chyang/.claude/plugins/my-workflow-plugin
同事機：${CLAUDE_PLUGIN_ROOT} = /Users/alice/.claude/plugins/my-workflow-plugin
```

---

## Step 3：用 install-skill.sh 安裝（模擬）

### 閱讀任務

打開 `scripts/install-skill.sh`，回答：

1. 這個腳本需要幾個參數？分別是什麼？

   答：**3 個參數**：

   | 位置 | 變數名 | 說明 | 必填？ |
   |------|--------|------|--------|
   | `$1` | `SKILL_NAME` | 要安裝的 Skill 名稱 | ✅ 必填（缺少直接 exit 1）|
   | `$2` | `REPO_URL` | GitHub repository URL | ✅ 必填（缺少直接 exit 1）|
   | `$3` | `SCOPE` | `project` 或 `personal` | ❌ 選填（預設 `project`）|

2. `SCOPE` 參數的兩個選項（project / personal）分別把 Skill 安裝到哪裡？

   | SCOPE | 安裝路徑 |
   |-------|---------|
   | `project` | `.claude/skills/${SKILL_NAME}`（相對路徑，當前專案目錄下）|
   | `personal` | `${HOME}/.claude/skills/${SKILL_NAME}`（全域個人設定）|

3. 腳本如何避免重複安裝（已存在時怎麼處理）？

   答：用 `if [ -d "$DEST" ]` 檢查目標目錄是否已存在，若存在直接
   `echo "錯誤：$DEST 已經存在" >&2 && exit 1`。

   這是「失敗快、失敗明確」的設計：
   - 不靜默覆蓋（那會讓使用者自訂的 Skill 被遠端版本覆蓋）
   - 不靜默略過（那讓使用者誤以為安裝成功，但實際上是舊版）

   腳本整體流程：

   ```
   參數解析（必填缺少 → exit 1）
   → 決定安裝路徑（project / personal）
   → 檢查是否重複（已存在 → exit 1）
   → git clone --depth=1（淺複製，只拿最新）
   → 在 tmp 目錄找 skills/${SKILL_NAME}/
   → cp -r 到目標路徑
   → trap 確保 tmp 目錄離開時自動清除
   ```

### 模擬安裝指令

```bash
# 模擬從 GitHub 安裝（用本地路徑示範）
bash code-中文/part7-workflows/scripts/install-skill.sh \
     confidence-check \
     https://github.com/example/skills \
     personal
```

### 實際結果

`install-skill.sh` 是「一行指令取代口頭說明」的具體實現。
沒有這個腳本時，文件通常是「把這個資料夾複製到 ~/.claude/skills/」——
容易複製錯、路徑搞混、或乾脆忘記做。

---

## Step 4：思考 Plugin 生態系統

### 討論問題

1. 如果你的團隊用同一套 Plugin，「部落知識」會消失的原因是什麼？

   答：Plugin 把「設定知識」從「人腦」搬到「程式碼」：

   ```
   傳統方式：
     老成員 → 口頭告知「記得裝 confidence-check，把這個 Hook 加到 settings.json...」
     新成員 → 記錯或忘掉一個步驟 → 本機配置不一致

   Plugin 方式：
     一條指令：git clone + 安裝腳本
     新成員的環境和老成員完全一致
     設定本身就是文件（plugin.json 說明這是什麼、hooks.json 說明做什麼）
   ```

   部落知識消失的根本原因：**設定的重現成本從「問人」降到「一行指令」**。

2. Plugin 版本號（1.0.0）的意義是什麼？當你修改了 Hook 行為後，應該升到幾版？

   答：版本號遵循 **Semantic Versioning（語義版本）**：`主版本.次版本.修補版本`

   | 變更類型 | 升哪一位 | 範例 |
   |---------|---------|------|
   | 破壞性變更（Hook 行為改變，影響現有使用者）| **主版本** | `1.0.0` → `2.0.0` |
   | 新增功能但不破壞現有行為 | 次版本 | `1.0.0` → `1.1.0` |
   | Bug 修復 / 文件更新 | 修補版本 | `1.0.0` → `1.0.1` |

   **修改了 Hook 行為後 → 應升到 `2.0.0`（主版本）**。
   主版本升版是信號：「這次更新不向後相容，請先確認影響範圍再升級。」

3. `${CLAUDE_PLUGIN_ROOT}` 這個環境變數的設計，解決了什麼硬編碼路徑的問題？

   答：Hook 腳本路徑如果寫死，換機器就壞掉。
   `${CLAUDE_PLUGIN_ROOT}` 讓 Claude Code 在安裝/載入 Plugin 時自動注入實際路徑，
   確保跨機器可攜性——和這些設計哲學一脈相承：

   | 場景 | 可攜寫法 | 禁止寫法 |
   |------|---------|---------|
   | Python 路徑 | `Path.home()` | `C:/Users/peter/` |
   | Shell 路徑 | `$HOME` | `/home/peter/` |
   | Plugin Hook | `${CLAUDE_PLUGIN_ROOT}` | `/Users/peter/.claude/plugins/xxx/` |

### 實際結果

「自我進化」不是科幻概念，它的實作只有三個元件：

**Plugin 是 Part 7 所有機制的「出口」**：
幻覺偵測、檢查清單、動態編排、七階段工作流、Worktree、自我進化——
這些都是個人技巧；Plugin 讓它們變成**團隊能力**。

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
