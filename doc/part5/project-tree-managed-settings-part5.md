# Project Tree — managed-settings

- 生成日期：2026-06-12
- 掃描目標：`C:\Users\B00332\workspace\kindle-20-65-automation-patterns\code\part5-security\managed-settings`
- 統計：0 個子資料夾 / 2 個檔案 / 排除 0 個噪音目錄

```
managed-settings/                  # Part 5 資安：企業級「受管控設定」範本（使用者無法覆蓋的最高層）
├── managed-settings.json          # 受管控設定本體：deny force push/npm publish/讀 ~/.* 與 /etc，停用 bypass 權限模式、只允許受管權限規則
└── com.anthropic.claudecode.plist # macOS 部署用 plist：同樣 disableBypassPermissionsMode + deny 危險指令，由 MDM 派送到全機
```

## 結構特徵

- 這層設定優先級最高，**使用者 / 專案 settings 都無法覆蓋**，是組織強制安全基線的手段。
- 兩個檔案內容對應：`.json` 給跨平台 managed settings 路徑，`.plist` 給 macOS 透過 MDM/Profile 派送。
- 關鍵欄位 `disableBypassPermissionsMode: "disable"` + `allowManagedPermissionRulesOnly: true`——禁止任何人用 bypass 模式繞過權限，且只認受管規則。


```
