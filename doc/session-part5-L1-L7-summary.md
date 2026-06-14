# Session 摘要：Part 5 權限與資安（第 1-7 課）

日期：2026-06-15

## 本 Session 完成

### Part 5 權限與資安（全 7 課）

| 課 | 主題 | 關鍵收穫 |
|----|------|---------|
| 1 | Deny > Ask > Allow 優先順序 | 系統層攔截 vs 語言層約束；疲憊工程師效應；移除決策點的防禦哲學 |
| 2 | Bash 空格陷阱 | 有空格 = 單字邊界（安全）；無空格 = 前綴比對（危險）；lsof 是典型受害者 |
| 3 | 三層分層權限 | 風險矩陣（可逆/影響）決定 Deny/Ask/Allow；確認疲勞是「全部 Ask」的最大陷阱 |
| 4 | 唯讀審查模式 | `defaultMode: dontAsk` + 五層封鎖；settings.json vs `--permission-mode plan` 的選擇 |
| 5 | 管理設定鐵腕政策 | `allowManagedPermissionRulesOnly` 廢開發者 Allow；`disableBypassPermissionsMode` 焊死逃生門；MDM 才能真正不可繞過 |
| 6 | Hook 攔截器 | exit 0/1/2 三種 exit code；exit 2 = 教育型防護（AI 讀 reason 自修正）；內容掃描 vs 環境感知兩種模式 |
| 7 | 沙盒防暴玻璃箱 | OS 層 allowedDomains 白名單；Proxy 稽核流量；唯一能防 Prompt Injection 的一層 |

## 核心技術要點

```
三層防禦體系：

  第一層：Permission Model（Claude Code 層）
    Deny > Ask > Allow 絕對優先順序
    工具呼叫瞬間攔截，早於 AI 開口解釋
    弱點：AI 被 Prompt Injection 欺騙後，判斷能力已被污染

  第二層：Hook 攔截器（應用層）
    PreToolUse 事件觸發，工具執行前決定放行或阻斷
    exit 2 + reason JSON = AI 知道原因，可自行修正
    弱點：仍依賴 Claude Code 觸發，Prompt Injection 可能繞過

  第三層：OS 沙盒（系統層）
    allowedDomains 白名單：DNS/TCP 層直接切斷
    Proxy：完整稽核 AI 的網路行為（取證能力）
    唯一不假設 AI 有良好意志的防禦層

三層選擇原則：
  「AI 主動搞破壞」→ 第一層 Deny
  「AI 被說服（仍在框架內）」→ 第二層 Hook
  「AI 被 Prompt Injection 完全劫持」→ 只有第三層能擋
```

```
關鍵易混淆點：

  Bash(ls *)  ← 有空格 = 單字邊界（安全，lsof 不通過）
  Bash(ls*)   ← 無空格 = 前綴比對（危險，lsof 通過）

  exit 1 = 硬擋（使用者看 stderr，AI 不知原因）
  exit 2 = 智慧擋（AI 看 reason JSON，可自修正）

  settings.json（永久）vs --permission-mode plan（一次性 CI）
  JSON 放 repo（可被改）vs MDM 部署系統層（沒 root 改不了）

  Deny 規則：靜態 pattern match
  Hook：動態腳本（讀環境變數、掃內容、呼叫外部）
```

## Commit 清單

| Commit | 說明 |
|--------|------|
| 2daf367 | Part5 第 1 課：Deny > Ask > Allow 優先順序 |
| 64a8e1a | Part5 第 2 課：Bash 空格陷阱 |
| 885458b | Part5 第 3 課：三層分層權限 |
| a01c649 | Part5 第 4 課：唯讀審查模式 |
| b8858e8 | Part5 第 5 課：管理設定鐵腕政策 |
| 4d4ebd3 | Part5 第 6 課：Hook 攔截器 |
| 31bbaf6 | Part5 第 7 課：沙盒防暴玻璃箱 |

## 下次繼續

Part 6：成本最佳化
對應目錄：`code-中文/part6-cost-optimization/`
