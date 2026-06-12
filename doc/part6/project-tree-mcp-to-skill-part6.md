# Project Tree — mcp-to-skill

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part6-cost\mcp-to-skill`
- 統計：0 個子資料夾 / 2 個檔案 / 排除 0 個噪音目錄

```
mcp-to-skill/    # Part 6 成本：把「只做一件小事的 MCP server」改寫成 Skill 省基礎設施開銷的範例
├── README.md    # 說明問題與解法：單純抓文件/跑 CLI 的 MCP 增加 server 進程+設定+維護成本，改用 SKILL.md + 內建工具更划算（含 trade-off）
└── SKILL.md     # 替代品 fetch-docs skill：allowed-tools 限 curl/npx，抓取並摘要指定函式庫官方文件
```

## 結構特徵

- 一組對照範例：用 `SKILL.md` 取代「只抓文件」的 MCP server，省去常駐 server 的進程/設定/維護成本。
- `SKILL.md` 用 `allowed-tools: Bash(curl *), Bash(npx *)` 收斂權限，是「輕量 skill > 重型 MCP」成本論點的具體實作。

```
