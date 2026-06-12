# Project Tree — plugin-example

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part7-workflows\plugin-example`
- 統計：2 個子資料夾 / 2 個檔案 / 排除 0 個噪音目錄

```
plugin-example/                # Part 7 工作流：團隊共享 plugin 的最小結構範例
├── .claude-plugin/
│   └── plugin.json            # plugin 清單：name my-team-plugin、version 1.0.0、團隊共享 Skills/Hooks/Agents、MIT 授權
└── hooks/
    └── hooks.json             # plugin 內建 hook：PostToolUse 匹配 Write|Edit 時跑 ${CLAUDE_PLUGIN_ROOT}/scripts/lint.sh
```

## 結構特徵

- 展示一個可分發 plugin 的最小骨架：`.claude-plugin/plugin.json`（清單）+ `hooks/hooks.json`（綁定 hook）。
- `hooks.json` 用 `${CLAUDE_PLUGIN_ROOT}` 變數定位 plugin 內腳本，讓 plugin 安裝到任意路徑都能正確引用——這是 plugin 可攜性的關鍵。
- 用途：把團隊共用的 Skills/Hooks/Agents 打包，一次分發給整個團隊。


```
