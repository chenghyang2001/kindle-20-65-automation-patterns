# 第 3 課演練記錄：三層分層權限（Deny / Ask / Allow）

> 對應文件：`code-中文/part5-security/permissions/layered-permissions.json`

## 課程目標

學會把操作分成「絕對禁止 / 需要確認 / 自動允許」三個層次，
理解每個層次背後的風險判斷邏輯，
掌握完整的分層權限設計，讓 AI 既能流暢工作又不踩地雷。

## 工作目錄

`code-中文/part5-security/demo/03-三層分層權限/`

---

## Step 1：閱讀 layered-permissions.json，分析三層設計

### Deny（絕對禁止）

| 規則 | 為什麼是 Deny 而不是 Ask？ |
|------|------------------------|
| `Bash(git push *)` | 推到遠端後影響所有協作者，`--force` 可覆寫他人 commit，不可逆 |
| `Bash(npm publish *)` | 發佈到公開 npm registry，全球可見，無法真正「撤銷」（deprecate 只是標記） |
| `Bash(rm -rf *)` | 遞迴強制刪除，若無備份則不可回復，Ask 來不及阻止已發動的刪除 |
| `Read(./.env)` | 機密一旦讀取即洩漏（進入 AI context），洩漏後不可回收 |
| `Read(./.env.*)` | 同上，涵蓋所有環境版本（.env.local、.env.production 等） |
| `Read(./secrets/**)` | 私鑰、API Key 讀取 = 洩漏，即使 Ask 後允許也已進入 AI context |

### Ask（需要人類確認）

| 規則 | 為什麼是 Ask 而不是 Deny 或 Allow？ |
|------|----------------------------------|
| `Bash(git commit *)` | commit 可 revert 但留在 history；合理開發流程需要 commit，但人類應確認每次內容 |
| `Bash(docker run *)` | 可能暴露通訊埠/掛載目錄/啟動特權 container；不是每次都危險，所以 Ask 而非 Deny |

### Allow（自動允許）

| 規則 | 為什麼是 Allow 而不是 Ask？ |
|------|--------------------------|
| `Bash(npm run lint)` | 唯讀掃描，不修改檔案，頻繁執行，每次問 = 開發流程中斷 |
| `Bash(npm run test *)` | 本地測試，不影響外部系統，需要頻繁跑，Ask 會拖慢 TDD 流程 |
| `Bash(git status)` | 完全唯讀，查看狀態不改變任何東西 |
| `Read(src/**)` | `src/` 是 AI 的主要工作區，讀取是正常開發行為，每次 Ask = 無法工作 |
| `Edit(src/**)` | AI 的核心職責就是寫 `src/` 裡的程式碼，限制 Edit = 廢掉 AI |

### 實際結果

讀取 layered-permissions.json 確認：6 條 Deny（不可逆 + 機密）、2 條 Ask（可逆但有副作用）、8 條 Allow（核心工作區 + 唯讀操作）。

---

## Step 2：理解三層之間的風險判斷框架

### 風險矩陣

| | 低影響範圍 | 高影響範圍 |
|---|-----------|-----------|
| **可逆操作** | Allow（如 `git diff`） | Ask（如 `git commit`） |
| **不可逆操作** | Ask（視情況） | **Deny**（如 `git push --force`） |

### 回答

1. `git commit` 為什麼是 Ask 而不是 Allow？

   答：commit 本身可以 `git revert` 撤銷，但有兩個副作用：
   (1) **commit 永遠留在 history** — 即使撤銷，原始 commit 和 revert commit 都留著，不小心 commit 的機密資訊無法真正抹去
   (2) **commit message 是對外溝通** — AI 自動 commit 的訊息品質和意圖需要人類確認
   保留 Ask 讓人類保有「最後一道審核關卡」。

2. `npm run lint` 為什麼是 Allow 而不是 Ask？

   答：lint 是靜態分析工具——讀取程式碼、找出風格/語法問題，**不修改任何檔案**（除非明確加了 `--fix`）。零副作用的唯讀操作不需要詢問，頻繁執行不打擾使用者。

3. `docker run *` 為什麼是 Ask？

   答：`docker run` 可能做的危險事：
   - `docker run --privileged` — 逃逸 container 存取宿主機 kernel
   - `docker run -v /:/host` — 掛載整個根目錄
   - `docker run -p 0.0.0.0:8080:8080` — 暴露通訊埠到所有網路介面
   不是每次都危險（`docker run hello-world` 無害），所以是 Ask（人類看一眼）而非 Deny（完全禁止）。

4. 如果把所有操作都設成 Ask，會有什麼問題？

   答：「確認疲勞（confirmation fatigue）」——詢問框出現太頻繁，人類開始反射性按「允許」而不閱讀內容。諷刺的是：**Ask 太多 = 比 Allow 還不安全**，因為 Allow 是預期的自動化，Ask 太多是假裝有把關但實際上沒有。

### 實際結果

理解風險矩陣：可逆/低影響 → Allow；可逆/高影響 → Ask；不可逆/高影響 → Deny。確認疲勞是「全部 Ask」設計的最大陷阱。

---

## Step 3：設計一套「AI 協助 Code Review」的分層權限

### 需求

- ✅ 讀取 `src/` 和 `tests/` 所有檔案
- ✅ 執行 `npm run test` 和 `npm run lint`
- ✅ 查看 `git diff`
- ❌ 不允許修改任何檔案
- ❌ 不允許 `git commit` 或 `git push`

### 設計

```json
{
  "permissions": {
    "deny": [
      "Edit(src/**)",
      "Edit(tests/**)",
      "Edit(./**)",
      "Bash(git commit *)",
      "Bash(git push *)",
      "Bash(git add *)"
    ],
    "ask": [],
    "allow": [
      "Read(src/**)",
      "Read(tests/**)",
      "Bash(npm run test *)",
      "Bash(npm run lint)",
      "Bash(git diff *)",
      "Bash(git status)",
      "Bash(git log *)"
    ]
  }
}
```

### 設計決策說明

- `deny: Edit(./**)` — 最強保護，禁止修改任何檔案（Code Review 是純閱讀任務）
- `ask: []` — Code Review 沒有「需要詢問的灰色地帶」，非讀即禁
- `allow: Read(src/**)` + `Read(tests/**)` — AI 必須能讀才能審查
- `allow: npm run test/lint` — 執行後看結果，不修改程式碼，是審查的一部分

### 實際結果

設計完整三層 JSON：6 條 deny 禁止所有寫入、0 條 ask（Code Review 非黑即白）、7 條 allow 開放所有審查必要操作。

---

## Step 4：對比三份 permissions 設定的用途差異

### 比較表

| 設定檔 | 主要用途 | Deny 的重點 | Allow 的重點 |
|--------|---------|-----------|------------|
| `deny-sensitive-files.json` | 機密保護（單一目的） | 讀取/修改 .env 和 secrets/ | 無（不開放額外操作） |
| `bash-patterns.json` | Bash 指令白名單（完整開發工作流） | 推送、下載、危險刪除 | 全套 git、npm、版本查詢 |
| `layered-permissions.json` | 三層完整權限設計（含 Ask） | 不可逆操作 + 機密 | 核心工作區 src/ 的讀寫 |

### 思考

1. 可不可以把三個設定檔合併成一個？有什麼優缺點？

   答：**技術上可以，實務上不建議。**
   - 優點：只需維護一個檔案，不會出現規則衝突
   - 缺點：用途混在一起，難以理解「為什麼這條規則在這裡」；更新機密保護規則需要在大 JSON 裡搜尋；無法針對不同情境（CI 環境 vs 本機開發）套用不同設定檔

   最佳實踐：依**用途分檔**，需要疊加時用 `extends` 合併，每個檔案保持單一職責。

2. 為什麼 `layered-permissions.json` 把 `Allow(Edit(src/**))` 放進去？

   答：這是最重要的設計概念——**Allow 不是「開放危險區域」，而是「標記安全工作區，讓 AI 自由行動，節省互動成本」。**

   在某些 default 模式下，`Edit(src/**)` 可能需要人類確認。把它放進 Allow 的意思是：「`src/` 是 AI 的主要工作區，我明確授權 AI 可以自由修改這裡，不需要每次詢問。」

   類比：辦公室員工在自己的桌子上工作不需要每次報批，但進入主管辦公室要敲門（Ask），進入機密室要被擋下（Deny）。

### 實際結果

理解三份設定各司其職：機密保護 / 指令白名單 / 完整三層——分檔設計更易維護，依情境選擇套用。

---

## 本課重點

```
三層的判斷邏輯：

  Deny：
    → 不可逆 + 高影響（一錯難回頭）
    → 機密相關（.env、secrets/）
    → 外部發布（git push、npm publish）

  Ask：
    → 可逆但有副作用（git commit 可 revert，但留 history）
    → 啟動外部資源（docker run 可能暴露通訊埠）
    → 你想保留「人類最後一關」的操作

  Allow：
    → 唯讀查詢（git status、git diff、grep）
    → 本地安全測試（npm run test、npm run lint）
    → 核心工作區的讀寫（src/** 是 AI 應該自由工作的地方）

設計原則：
  Ask 不是萬能的（全部 Ask = 確認疲勞 = 反射性按允許 = 比 Allow 還危險）
  Deny 不是越多越好（把所有東西 Deny = AI 什麼都做不了）
  目標：讓 AI 在「安全工作區」裡自由工作，在「危險邊界」設關卡

設定檔單一職責：
  機密保護一個檔 / 指令白名單一個檔 / 完整三層一個檔
  依情境套用，不要全部堆在一起
```
