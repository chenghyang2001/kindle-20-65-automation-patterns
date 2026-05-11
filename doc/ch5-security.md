# 第5章 Security Blueprint — AI 代理的三層資安防禦

> Claude Code in Production | Yosuke Morikawa | Patterns 53–57

---

## 章節概覽

AI 代理有能力寫檔、執行 shell、呼叫 API——這些都是資安風險面。
本章建立**三層防禦**：Permission（什麼不能做）、Hooks（動態攔截）、Managed Settings（企業管控）。

---

## 核心模式

### Pattern 53：三層 Permission 架構

```json
// layered-permissions.json
{
  "permissions": {
    "deny": [
      "Bash(git push *)",
      "Bash(npm publish *)",
      "Bash(rm -rf *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ],
    "ask": [
      "Bash(git commit *)",
      "Bash(docker run *)"
    ],
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test *)",
      "Bash(npm run build *)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Read(src/**)",
      "Edit(src/**)"
    ]
  }
}
```

**三層邏輯：**
- `deny`：永遠封鎖，AI 連嘗試的機會都沒有
- `ask`：執行前詢問使用者確認
- `allow`：無需確認直接執行

**設計原則：deny 要明確（用路徑 glob），allow 要精確（不要 allow *）。**

---

### Pattern 54：唯讀 Review 模式

```json
// readonly-review.json
{
  "permissions": {
    "allow": ["Read(**)", "Grep(**)", "Glob(**)"],
    "deny": ["Write(**)", "Edit(**)", "Bash(**)", "MCP(**/*.write)"]
  }
}
```

Code review 場景：AI 只能讀，不能改任何東西。

---

### Pattern 55：Sandbox 沙箱設定

```json
// sandbox-config.json
{
  "permissions": {
    "allow": [
      "Bash(docker *)",
      "Read(/workspace/**)",
      "Write(/workspace/**)"
    ],
    "deny": [
      "Read(/etc/**)",
      "Read(/home/**)",
      "Read(~/.ssh/**)",
      "Bash(ssh *)",
      "Bash(curl *)",
      "Bash(wget *)"
    ]
  }
}
```

把 AI 限制在 `/workspace/` 內，不能讀 SSH keys，不能對外 HTTP。

---

### Pattern 56：Secret Scanner Hook（PostToolUse）

```bash
# secret-scanner.sh — 完整版（支援 8 種 secret 格式）
NAMES=(    "AWS"                     "GITHUB"                   "ANTHROPIC"                 "OPENAI"             "GOOGLE"                  "STRIPE"                            "PRIVKEY")
PATTERNS=( "AKIA[0-9A-Z]{16}"       "gh[ps]_[A-Za-z0-9]{36}"  "sk-ant-[A-Za-z0-9\-]{95}" "sk-[A-Za-z0-9]{48}" "AIza[0-9A-Za-z\-_]{35}" "(sk|pk)_(test|live)_[A-Za-z0-9]{24}" "-----BEGIN.*PRIVATE KEY-----")

for i in "${!NAMES[@]}"; do
  if echo "$CONTENT" | grep -qE "${PATTERNS[$i]}"; then
    echo "{\"decision\":\"block\",\"reason\":\"${NAMES[$i]} secret detected\"}" >&2
    exit 2
  fi
done
```

觸發時機：AI 嘗試寫入/編輯檔案時（Write/Edit）→ 掃描內容 → 有 secret 就 block。

---

### Pattern 57：Dev Server 封鎖 + Managed Settings

#### dev-server-blocker.sh

```bash
# 防止 AI 在 CI 環境啟動 dev server（會 block CI 永不結束）
if echo "$COMMAND" | grep -qE "npm run dev|next dev|vite|webpack-dev-server"; then
  if [ "${CI:-false}" = "true" ]; then
    echo '{"decision":"block","reason":"Dev server not allowed in CI"}' >&2
    exit 2
  fi
fi
```

#### Managed Settings（企業級管控）

```json
// managed-settings.json — IT 管理員透過 MDM 推送，使用者無法覆蓋
{
  "permissions": {
    "deny": [
      "Bash(curl * production*)",
      "Read(/etc/passwd)",
      "Bash(sudo *)"
    ]
  },
  "disabledFeatures": ["prompt-caching"],
  "allowedModels": ["claude-sonnet-4-5", "claude-haiku-4-5"]
}
```

macOS 放到 `/Library/Managed Preferences/com.anthropic.claudecode.plist`，Windows 用 Group Policy。

---

## Bash Patterns（精確授權）

```json
// bash-patterns.json — 精確到參數層級
{
  "permissions": {
    "allow": [
      "Bash(git log *)",
      "Bash(git diff * -- src/**)",
      "Bash(npm run test -- --testPathPattern=*)"
    ],
    "deny": [
      "Bash(git push *)",
      "Bash(git tag *)"
    ]
  }
}
```

`Bash(git diff * -- src/**)` 允許 diff，但只允許 `src/` 下的檔案。

---

## 如何套用到我的工作流

| 場景 | 推薦設定 |
|------|---------|
| 日常開發 | `layered-permissions.json`（基本 deny 清單）|
| PR 審查 | `readonly-review.json`（只讀） |
| VPS 自動化 | `sandbox-config.json`（限制目錄 + 無外網） |
| 企業 CI | `managed-settings.json`（MDM 推送） |

**立即可做：把 `block-dangerous.sh`（Ch2）+ `secret-scanner.sh`（本章）加到 hooks 設定。**

---

## 最值得馬上借鑑

1. **`deny-sensitive-files.json`：保護 `.env` 和 `secrets/`**
   ```json
   {"permissions": {"deny": ["Read(.env*)", "Read(secrets/**)", "Read(~/.ssh/**/**)"]}}
   ```
   最小成本，防止最常見的 secret 洩漏。

2. **`layered-permissions.json` 加入 `proxy-config.json`**
   - 所有外部 HTTP 請求透過可稽核的 Proxy
   - 讓 AI 不能繞過安全邊界直接連外部

---

## Sample Code 位置

```
code/part5-security/
├── permissions/
│   ├── layered-permissions.json  ← 三層 allow/ask/deny
│   ├── readonly-review.json      ← 唯讀 Review 模式
│   ├── sandbox-config.json       ← 沙箱隔離
│   ├── bash-patterns.json        ← 精確 Bash 授權
│   ├── deny-sensitive-files.json ← 敏感檔案保護
│   └── proxy-config.json         ← HTTP Proxy 設定
├── hooks/
│   ├── secret-scanner.sh         ← Secret 洩漏偵測
│   └── dev-server-blocker.sh     ← Dev server CI 防護
└── managed-settings/
    ├── managed-settings.json       ← 企業統一管控
    └── com.anthropic.claudecode.plist ← macOS MDM 格式
```
