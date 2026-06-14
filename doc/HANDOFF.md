# 交接文件 — kindle-20-65-automation-patterns

> 建立時間：2026-06-15
> 用途：家用 PC → 公司 PC 切換時，讓另一台機器的 Claude Code 能立即接續演練

---

## 當前進度

| Part | 主題 | 狀態 |
|------|------|------|
| Part 1 | 設計基礎 | ✅ 7 課全部完成 |
| Part 2 | Hooks | ✅ 已建立（課程狀態待確認） |
| Part 3 | Sub-agents | ✅ 7 課全部完成 |
| Part 4 | CI/CD | ✅ 7 課全部完成 |
| Part 5 | 權限與資安 | ✅ 7 課全部完成（commit d1566b2） |
| Part 6 | 成本最佳化 | 🔲 **待開始**（下一個要做的） |
| Part 7 | Plugin | 🔲 待開始 |

**下一步：Part 6 第 1 課「看懂 Token 帳單」**

---

## 工作模式（互動演練課程）

固定流程：

1. 助理呈現課程題目（4 Step 結構）
2. 使用者說「**answer**」→ 助理填入解答
3. 使用者說「**存檔進第 N 課**」→ 助理寫 STEP-LOG.md + commit + push
4. 助理自動呈現下一課

說「**繼續 Part 6**」即可從第 1 課開始。

---

## 關鍵目錄

```
kindle-20-65-automation-patterns/
├── code-中文/
│   ├── part5-security/     ← Part 5 源碼（已完成）
│   └── part6-cost/         ← Part 6 源碼（待演練）
│       ├── cost-monitoring.md          ← 第 1 課對應文件
│       ├── model-selection-matrix.md   ← 第 2 課對應文件
│       ├── docs/cache-design-guide.md  ← 第 3 課對應文件
│       ├── hooks/suggest-compact.sh    ← 第 4 課對應文件
│       ├── agents/code-explorer.md     ← 第 5 課對應文件
│       ├── mcp-to-skill/SKILL.md       ← 第 6 課對應文件
│       ├── settings/                   ← 多課共用設定
│       └── demo/                       ← 7 個 STEP-LOG 空白模板在這
└── doc/
    ├── session-part5-L1-L7-summary.md ← Part 5 完課摘要
    └── HANDOFF.md                      ← 本交接文件
```

---

## Part 6 課程地圖

| 課 | 主題 | 對應源碼 |
|----|------|---------|
| 1 | 看懂 Token 帳單 | `cost-monitoring.md` |
| 2 | 模型選擇矩陣 | `model-selection-matrix.md` |
| 3 | Prompt 快取設計 | `docs/cache-design-guide.md` |
| 4 | 成本警示 Hook | `hooks/suggest-compact.sh` |
| 5 | Sub-agent 套利 | `agents/code-explorer.md` |
| 6 | MCP 轉 Skill | `mcp-to-skill/SKILL.md` |
| 7 | 組合拳全面控制 | `settings/` 目錄下多個設定 |

---

## 公司 PC 環境確認

切換到公司 PC 後，請確認：

```bash
# 1. clone / pull 最新狀態
cd ~/workspace
git clone https://github.com/chenghyang2001/kindle-20-65-automation-patterns.git
# 或已有 repo 時：
git pull

# 2. 確認 git user
git config user.name   # 應為：ChengHsien Yang
git config user.email  # 應為：chenghyang2001@gmail.com

# 3. 確認 Claude Code 登入（Max 訂閱模式）
claude --version
```

---

## 最後 5 個 commit

```
d1566b2  新增 Part5 第 1-7 課 session 摘要文件
31bbaf6  存檔 Part5 第 7 課：沙盒防暴玻璃箱
4d4ebd3  存檔 Part5 第 6 課：Hook 攔截器
b8858e8  存檔 Part5 第 5 課：管理設定鐵腕政策
a01c649  存檔 Part5 第 4 課：唯讀審查模式
```

---

## 接續指令

在公司 PC 開啟 Claude Code 後，直接說：

> **繼續 Part 6**

助理會自動讀取本文件，從 Part 6 第 1 課開始演練。
