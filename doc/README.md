# Kindle-20 章節分析文件索引

**書名：** Claude Code in Production: 65 Automation Patterns for Hooks, Sub-Agents & CI/CD  
**作者：** Yosuke Morikawa  
**NotebookLM：** df631b4f-5ea4-40df-bba3-e2ad7131f385  
**分析日期：** 2026-05-12

---

## 章節文件清單

| 章節 | 文件 | 涵蓋 Patterns | 核心主題 |
|------|------|-------------|---------|
| 第1章 | [ch1-design-foundations.md](ch1-design-foundations.md) | P1–P10 | CLAUDE.md 三層架構、Skills 設計 |
| 第2章 | [ch2-hooks-automation.md](ch2-hooks-automation.md) | P11–P27 | 17 個 Hooks、品質守門、安全防護 |
| 第3章 | [ch3-sub-agents.md](ch3-sub-agents.md) | P28–P44 | Sub-agents vs Teams、模型矩陣、反理由化 |
| 第4章 | [ch4-cicd-automation.md](ch4-cicd-automation.md) | P45–P52 | GitHub Actions、平行 Review、JSON 輸出 |
| 第5章 | [ch5-security.md](ch5-security.md) | P53–P57 | 三層 Permission、Secret 掃描、Managed Settings |
| 第6章 | [ch6-cost-optimization.md](ch6-cost-optimization.md) | P58–P61 | Prompt Cache、模型選擇、MCP→Skill 遷移 |
| 第7章 | [ch7-production-workflows.md](ch7-production-workflows.md) | P62–P65 | Checkpointing、幻覺偵測、Cascade 模式 |

---

## 最值得立刻套用的 10 件事

1. **Ch1：Skills `description` 加觸發 + 排除條件** → 停止 AI 亂觸發 Skill
2. **Ch1：CLAUDE.md 穩定區置頂** → prompt cache 命中率大升
3. **Ch2：`block-dangerous.sh` 加入 hooks** → 防 `rm -rf` 意外
4. **Ch2：`secret-scanner.sh` 加入 PostToolUse** → 防 API Key 洩漏
5. **Ch3：rationalization-prevention.md 加入 AGENT.md** → 代理不再找藉口停工
6. **Ch3：探索型代理換 haiku 模型** → 60-80% 子代理成本節省
7. **Ch4：`parallel-review.sh` 平行三維度審查** → 審查時間縮短 2/3
8. **Ch5：`readonly-review.json`** → PR review 時 AI 只讀不改
9. **Ch6：停用不用的 MCP server** → 立即減少每次對話 context
10. **Ch7：四個驗證問題加入收工 SOP** → 防幻覺悄悄進生產

---

## NotebookLM Artifacts 完成度

| 類型 | 數量 | 狀態 |
|------|------|------|
| Audio（語音摘要） | 7/7 | ✅ 全部完成 |
| Video（影片摘要） | 6/7 | ⏳ Ch3 pending |
| Slide Deck（簡報） | 7/7 | ✅ 全部完成 |

---

## 目錄結構

```
Kindle-20-Yosuke-65-Automation-Patterns/
├── audio/          ← 7 個 .m4a 語音摘要
├── PPTX/           ← 7 個 .pdf 簡報（NLM slide deck）
├── PDF/
│   ├── kindle20-part1-ch1-3.pdf
│   ├── kindle20-part2-ch4-7.pdf
│   └── chapters/   ← 7 個章節 PDF
├── PNG/            ← 239 頁截圖
├── code/           ← GitHub sample code (forest6511/claude-code-in-production)
├── doc/            ← 本目錄：章節分析文件
└── kindle-20.m3u   ← VPS 音頻播放清單
```
