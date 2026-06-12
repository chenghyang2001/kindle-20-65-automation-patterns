# Project Tree — permissions

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part5-security\permissions`
- 統計：0 個子資料夾 / 6 個檔案 / 排除 0 個噪音目錄

```
permissions/                  # Part 5 資安：settings.json permissions 區段的 6 種範本
├── layered-permissions.json  # 完整三層範本：deny(push/publish/rm -rf/讀密鑰) + ask(commit/docker run) + allow(lint/test/build/讀寫 src)
├── bash-patterns.json        # Bash 指令白/黑名單：allow 唯讀 git+npm run，deny push/reset --hard/rebase/curl/wget/rm -rf
├── deny-sensitive-files.json # 只擋敏感檔：deny 讀寫 .env/.env.*/secrets/credentials
├── readonly-review.json      # 唯讀審查模式：defaultMode dontAsk，deny 所有寫入/網路/MCP，只 allow 讀 src+tests/Grep/Glob
├── sandbox-config.json       # 沙箱網路白名單：allowedDomains 限 npmjs/github/jsdelivr
└── proxy-config.json         # 沙箱 proxy 設定：httpProxyPort 8080 / socksProxyPort 8081
```

## 結構特徵

- 6 個 JSON 由簡到繁展示 `permissions` 的各種用法：單一面向（敏感檔、bash、唯讀）到三層組合（`layered-permissions.json`）。
- `readonly-review.json` 是「審查專用 profile」：`defaultMode: dontAsk` + 全面 deny 寫入，正好對應 part3 reviewer agents 的唯讀需求。
- `sandbox-config.json` / `proxy-config.json` 屬沙箱網路控制層：用網域白名單 + proxy 埠把 Claude 的對外連線關進可控通道。

```
