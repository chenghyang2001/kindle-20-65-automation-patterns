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

### Deny 清單的理由

| 被禁止的操作 | 為什麼這是組織層級要管的事？ |
|------------|--------------------------|
| `git push --force *` | 可覆寫任何人的 commit 歷史，影響整個團隊，不是個人問題 |
| `git push origin main` | main 分支是產品主線，直接推送繞過 PR/review 流程，影響所有使用者 |
| `git push origin master` | 同上（舊專案常用 master 作主分支名稱） |
| `npm publish *` | 發佈到公開 registry 影響全球使用者，必須有發佈流程授權 |
| `Read(//etc/**)` | `/etc/` 含系統配置（密碼 hash、sudoers、SSH config），讀取 = 資安漏洞 |
| `Read(~/.*)`| 家目錄隱藏檔含 `~/.ssh/`（私鑰）、`~/.aws/`（雲端憑證）、`~/.gitconfig`（身份），讀取 = 身份盜用 |

### 兩個鎖定開關

1. `allowManagedPermissionRulesOnly: true` 的意思：

   答：開發者在自己的 `settings.json` 加的任何 Allow 規則**全部無效、被忽略**。

   具體行為：
   - 開發者在 `.claude/settings.json` 加 `"allow": ["Bash(npm publish *)"]`
   - 結果：這條規則被忽略，AI 的實際行為：npm publish 仍然被拒絕

   防止「開發者幫自己開後門」——沒有組織明確授權就不能執行。

2. `disableBypassPermissionsMode: "disable"` 的作用：

   答：封鎖「Bypass Permission Mode」——一種可以暫時跳過所有權限限制的緊急模式。
   `FORCE_DIRECT_WRITE=1` 等逃生門被焊死：即使開發者知道這個模式，組織政策仍然生效，無法跳過。

### 實際結果

讀取 managed-settings.json 確認：6 條 Deny（保護生產分支/套件發布/系統機密）+ 兩個鎖定開關（allowManagedPermissionRulesOnly + disableBypassPermissionsMode）。

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

### 三層職責分工

| 設定層次 | 誰能修改 | 誰能被它覆蓋 | 適合放什麼規則 |
|---------|---------|------------|------------|
| 組織 Managed Settings | 只有 IT/安全部門（透過 MDM/GPO） | 所有個人與專案設定 | 全公司不可逾越的底線（生產環境保護、機密存取） |
| 個人 settings.json | 開發者本人 | 只有專案設定 | 個人習慣（偏好工具、常用 git 指令） |
| 專案 settings.json | 任何有 git 權限的人 | 無（最低層） | 當前專案特有需求（特定測試指令、特定路徑許可） |

### 思考問題

1. 為什麼 `git push origin main` 要組織層 Deny 而不是口頭規定？

   答：口頭規定三個失效場景：
   (1) 新人不知道（沒人告訴他）
   (2) 老人忘記了（手速快，忘了這條規則）
   (3) AI 不知道（沒有寫進 prompt，AI 按照指示直接推）

   口頭規定依賴「人類記得」；Managed Settings 依賴「系統強制」——在凌晨三點趕 deadline 時，只有系統強制是可靠的。

2. 開發者能在自己的 settings.json 把 `npm publish` 移除嗎？

   答：**不能**。`allowManagedPermissionRulesOnly: true` 讓開發者的個人 Allow 規則完全無效。Managed Settings 的 Deny 規則無法被下層覆蓋。正確做法：向 IT 申請，由他們在 Managed Settings 的 allow 清單中加例外。

3. `Read(~/.*)`（家目錄隱藏檔）Deny 保護了什麼？

   | 路徑 | 內容 | 洩漏後果 |
   |------|------|---------|
   | `~/.ssh/id_rsa` | SSH 私鑰 | 攻擊者可登入任何授權的伺服器 |
   | `~/.aws/credentials` | AWS 存取金鑰 | 可操控整個 AWS 帳號（刪 S3、開 EC2 挖礦） |
   | `~/.gitconfig` | Git 身份設定（含 token） | 可以以你的名義 commit、push |
   | `~/.npmrc` | npm 認證 token | 可以發布套件到你的帳號下 |
   | `~/.claude/settings.json` | Claude Code 的所有設定 | 可了解並繞過你的安全設定 |

### 實際結果

理解三層優先順序：組織 > 個人 > 專案，不可逆轉。口頭規定 vs 系統強制的核心差異：後者在任何條件下都生效。

---

## Step 3：閱讀 plist，理解 macOS MDM 部署機制

### 回答

1. plist 和 managed-settings.json 的差別？

   答：內容本質相同（同樣的 Deny 規則、同樣的鎖定開關），但**格式不同**：
   - plist：XML 格式，macOS MDM 的標準格式，可透過 Apple Business Manager / JAMF 直接部署到每台 Mac
   - JSON：Claude Code 直接讀取的格式

   MDM 讀 plist → 轉換為系統策略 → Claude Code 讀取系統策略執行

2. 為什麼需要 MDM 而不是直接放 repo？

   答：放 repo 的開發者繞過方式：
   (1) 直接編輯：`vim .claude/settings.json` 刪掉 Deny 規則
   (2) 覆蓋環境變數：用 `FORCE_DIRECT_WRITE=1` 跳過
   (3) 在 repo 外工作：建新目錄不受 repo 層設定影響

   MDM 部署到系統層（`/Library/Managed Preferences/`），開發者沒有 root 權限無法修改——這才是真正的「不可繞過」。

3. Allow 規則不生效的現象解釋：

   答：


   ```
   開發者的 settings.json：
     "allow": ["Bash(npm run deploy)"]
     
   MDM 設定：
     "allowManagedPermissionRulesOnly": true
     
   系統行為：
     讀取 Managed Settings → 看到 allowManagedPermissionRulesOnly: true
     → 忽略所有來自 ~/.claude 和 .claude 的 allow 規則
     → 開發者的 allow 被丟棄 → npm run deploy 被拒絕
```

   白話說：**「組織說了算，你的 Allow 規則無效」**。

### 實際結果

理解 plist 是 MDM 部署的格式橋樑；MDM 部署到系統層是唯一真正「不可繞過」的部署方式。

---

## Step 4：設計「初級工程師安全防護」的 Managed Settings

### 完整設定

```json
{
  "permissions": {
    "deny": [
      "Bash(git push --force *)",
      "Bash(git push origin main)",
      "Bash(git push origin production)",
      "Bash(npm publish *)",
      "Read(//etc/**)",
      "Read(~/.*)"
    ]
  },
  "allowManagedPermissionRulesOnly": true,
  "disableBypassPermissionsMode": "disable"
}
```

### 觀察

和原始 `managed-settings.json` 幾乎完全一樣（多了 `production` 分支保護）——原始設計本身就已經是「初級工程師安全防護」的最小完整實現。這說明 Managed Settings 的設計直接對應最小權限原則，不需要多餘規則。

### 實際結果

設計完成：6 條 Deny + 兩個鎖定開關，與原始設計高度吻合。

---

## 本課重點

```
Managed Settings 的兩個鎖定開關：

  allowManagedPermissionRulesOnly: true
    → 開發者在個人或專案 settings.json 加的 Allow 規則「全部無效」
    → AI 只能遵守組織明確允許的那些操作
    → 防止：開發者幫自己開後門

  disableBypassPermissionsMode: "disable"
    → 封鎖「暫時繞過所有限制」的模式（Bypass Permission Mode）
    → 即使開發者知道這個模式，也無法使用
    → 防止：開發者用緊急模式繞過組織政策

三層設定的職責分工：
  組織（IT/安全部門）→ 設定不可逾越的底線
  個人 → 在底線內設定個人習慣
  專案 → 在個人設定內調整當前專案需求

口頭規定 vs 系統強制：
  口頭規定依賴人類記得，凌晨三點趕 deadline 必定失效
  系統強制沒有「我忘了」「我以為可以」的空間

plist vs JSON：
  JSON 放 repo → 開發者可以直接改
  MDM 部署系統層 → 沒有 root 就改不了
  企業環境必須透過 MDM/GPO 部署才能真正「管理」
```
