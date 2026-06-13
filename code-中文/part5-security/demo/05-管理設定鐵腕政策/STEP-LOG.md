# 第 5 課演練記錄：管理設定鐵腕政策（Managed Settings）

> 對應文件：
>
> - `code-中文/part5-security/managed-settings/managed-settings.json`
> - `code-中文/part5-security/managed-settings/com.anthropic.claudecode.plist`

## 課程目標

理解組織層級的 Managed Settings 如何凌駕個別開發者的設定，
學會區分「個人專案設定」和「組織強制政策」的權責邊界，
掌握 `allowManagedPermissionRulesOnly` 和 `disableBypassPermissionsMode` 的作用。

## 工作目錄

`code-中文/part5-security/demo/05-管理設定鐵腕政策/`

---

## Step 1：閱讀 managed-settings.json，理解組織層強制規則

### 閱讀任務

打開 `managed-settings/managed-settings.json`，回答：

1. 這份設定的 Deny 清單禁止了哪些操作？

   | 被禁止的操作 | 為什麼這是組織層級要管的事？ |
   |------------|--------------------------|
   | `git push --force *` | |
   | `git push origin main` | |
   | `git push origin master` | |
   | `npm publish *` | |
   | `Read(//etc/**)` | |
   | `Read(~/.*)`| |

2. `allowManagedPermissionRulesOnly: true` 的意思是什麼？
   （提示：如果開發者在自己的 `settings.json` 裡加了一條新的 Allow 規則，這個設定會怎麼處理它？）

   答：

3. `disableBypassPermissionsMode: "disable"` 的作用是什麼？
   （提示：第 3、4 課裡有沒有辦法暫時跳過規則？這個設定封掉了什麼？）

   答：

### 實際結果

（演練時填入）

---

## Step 2：比較三個層次的設定，理解優先順序

### 架構圖

```
組織政策（Managed Settings）← 最高優先，開發者無法覆蓋
        ↓
個人設定（~/.claude/settings.json）← 適用所有專案
        ↓
專案設定（.claude/settings.json）← 只適用當前專案
```

### 填表

| 設定層次 | 誰能修改 | 誰能被它覆蓋 | 適合放什麼規則 |
|---------|---------|------------|------------|
| 組織 Managed Settings | 只有 IT/安全部門 | 所有個人與專案設定 | |
| 個人 settings.json | 開發者本人 | 只有專案設定 | |
| 專案 settings.json | 任何有 git 權限的人 | 無（最低層） | |

### 思考問題

1. 為什麼要把 `git push origin main` 設為組織層 Deny 而不是口頭規定？

   答：

2. 如果某個開發者說「我需要 `npm publish`，我的工作就是發布套件」，
   他能在自己的 settings.json 把它從 Deny 移除嗎？為什麼？

   答：

3. `Read(~/.*)`（讀取家目錄的隱藏檔案）被組織層 Deny。
   這保護了什麼？（想想 `~/.ssh/`、`~/.gitconfig`、`~/.aws/`）

   答：

### 實際結果

（演練時填入）

---

## Step 3：閱讀 plist，理解 macOS MDM 的部署機制

### 閱讀任務

打開 `managed-settings/com.anthropic.claudecode.plist`，回答：

1. plist 檔案的 `<key>managedPermissions</key>` 裡，規則內容和 `managed-settings.json` 有什麼差別？

   答：

2. 為什麼組織需要 MDM（Mobile Device Management）來部署這份設定？
   （提示：如果只是把 JSON 檔案放進 repo，開發者可以怎麼繞過？）

   答：

3. MDM 部署後，開發者打開 `~/.claude/settings.json` 發現某條 Allow 規則「不生效」。
   他去問 IT，IT 說這是 `allowManagedPermissionRulesOnly: true` 造成的。
   請解釋這個現象：

   答：

### 實際結果

（演練時填入）

---

## Step 4：設計「初級工程師安全防護」的 Managed Settings

### 情境

你的公司剛招了一批實習生和初級工程師，你是技術負責人。
你要設計一份 Managed Settings，確保他們無法意外破壞生產環境：

**必須禁止的操作（寫出 Deny 規則）：**

- 強制推送任何分支
- 推送到 main 或 production 分支
- 發布 npm 套件
- 讀取系統配置（`/etc/`）
- 讀取同事的家目錄下的隱藏檔案

**必須啟用的政策鎖定：**

- 不讓他們自己加新的 Allow 規則
- 不讓他們用「繞過模式」跳過規則

填入完整的 JSON 設定：

```json
{
  "permissions": {
    "deny": [
      （填入 Deny 規則）
    ]
  },
  "allowManagedPermissionRulesOnly": ___________,
  "disableBypassPermissionsMode": "___________"
}
```

### 實際結果

（演練時填入）

---

## 本課重點

```
Managed Settings 的兩個鎖定開關：

  allowManagedPermissionRulesOnly: true
    → 開發者在個人或專案 settings.json 加的 Allow 規則「全部無效」
    → AI 只能遵守組織明確允許的那些操作
    → 防止：開發者自己幫自己開後門

  disableBypassPermissionsMode: "disable"
    → 封鎖「暫時繞過所有限制」的模式（Bypass Permission Mode）
    → 即使開發者知道這個模式，也無法使用
    → 防止：開發者用緊急模式繞過組織政策

三層設定的職責分工：
  組織（IT/安全部門）→ 設定不可逾越的底線
  個人 → 在底線內設定個人習慣
  專案 → 在個人設定內調整當前專案需求

plist vs JSON：
  macOS MDM 用 plist 部署 → 開發者無法自行修改（系統層強制執行）
  JSON 放 repo → 開發者可以自行改掉（不可靠）
  企業環境必須透過 MDM/GPO 部署，才能真正「管理」
```
