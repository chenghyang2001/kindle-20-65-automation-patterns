# 第 4 課演練記錄：兩個安全 Front Matter 標籤

> 對應文件：
>
> - `code-中文/part1-design/skills/invocation-control/deploy.SKILL.md`
> - `code-中文/part1-design/skills/invocation-control/legacy-context.SKILL.md`

## 課程目標

理解 `disable-model-invocation: true` 和 `user-invocable: false` 這兩個標籤的用途，
學會區分「高風險操作需要人類守門」和「背景參考資料只給 AI 看」兩種場景，
掌握最小化 AI 自主觸發高危 Skill 風險的設計原則。

## 工作目錄

`code-中文/part1-design/demo/04-安全FrontMatter標籤/`

---

## Step 1：讀 deploy.SKILL.md，理解 disable-model-invocation

### 閱讀任務

打開 `skills/invocation-control/deploy.SKILL.md`，回答：

1. Front Matter 裡有哪個安全標籤？它的值是什麼？

   答：

2. 這個標籤的效果是什麼？AI 在對話中會看到這個 Skill 嗎？

   答：

3. 如果沒有這個標籤，AI 在什麼情況下可能自動觸發部署？

   （想像一個對話情境：開發者說了什麼，AI 可能誤觸）

   答：

4. 有了這個標籤後，要觸發部署的唯一方式是什麼？

   答：

### 實際結果

- 安全標籤：`disable-model-invocation: true`
- 效果：AI 知道這個 Skill 存在，但無法自動觸發；人類必須輸入 `/deploy` 顯式呼叫
- 沒有標籤時的誤觸情境：開發者說「功能做好了可以上線」→ AI 誤判情境相符 → 自動 push main
- 有標籤後唯一觸發方式：使用者手動輸入 `/deploy` 指令

---

## Step 2：讀 legacy-context.SKILL.md，理解 user-invocable: false

### 閱讀任務

打開 `skills/invocation-control/legacy-context.SKILL.md`，回答：

1. Front Matter 裡有哪個安全標籤？它的值是什麼？

   答：

2. 這個 Skill 描述的是什麼內容？（一句話摘要）

   答：

3. `user-invocable: false` 讓這個 Skill 從哪裡消失？還存在哪裡？

   | 位置 | 有沒有這個 Skill |
   |------|---------------|
   | 使用者介面的 Skill 選單 | |
   | AI 的可用工具列表 | |
   | 遇到相關工作時 AI 的參考資料 | |

4. 如果沒有 `user-invocable: false`，開發者的 Skill 選單會越來越長。
   這有什麼問題？

   答：

### 實際結果

- 安全標籤：`user-invocable: false`
- 內容摘要：2008 年舊版付款系統的技術背景與限制（PHP 5.6、Shift-JIS、XML-RPC）
- 效果：Skill 選單對人類隱藏；AI 可見並遇到相關任務自動讀入參考
- 沒有此標籤的問題：選單噪音、使用者認知負擔、背景資料混在可操作 Skill 裡造成誤用

---

## Step 3：比較兩個標籤的設計目的

### 填表

| 標籤 | 設計目的 | 誰看不到 | 誰看得到 | 適合什麼場景 |
|------|---------|---------|---------|------------|
| `disable-model-invocation: true` | | | | |
| `user-invocable: false` | | | | |

### 思考問題

1. 如果一個 Skill 同時加上這兩個標籤，會發生什麼？

   答：

2. 以下哪些 Skill 應該加 `disable-model-invocation: true`？（勾選）

   - [ ] 「分析這個 PR 的程式碼品質」
   - [ ] 「清空測試資料庫所有資料」
   - [ ] 「生成本週的工作進度報告」
   - [ ] 「把新版本發布到 npm registry」
   - [ ] 「搜尋有沒有類似的 bug 記錄」
   - [ ] 「強制 merge 到 main 分支」

3. 以下哪些 Skill 應該加 `user-invocable: false`？（勾選）

   - [ ] 「本公司 API 設計的內部慣例（30 頁文件）」
   - [ ] 「執行完整的 CI 流程」
   - [ ] 「舊版付款系統的背景資料和限制說明」
   - [ ] 「部署到生產環境」
   - [ ] 「公司技術債清單（AI 決策時參考）」

### 實際結果

| 標籤 | 設計目的 | 誰看不到 | 誰看得到 | 適合場景 |
|------|---------|---------|---------|---------|
| `disable-model-invocation: true` | 防 AI 自動觸發高危操作 | AI 無法觸發 | 人類（/指令顯式呼叫）| 部署、刪除、發布 |
| `user-invocable: false` | 對人類隱藏，保留 AI 參考 | 人類（選單消失）| AI（自動讀入）| 內部文件、技術背景 |

- Q1：兩個都加 → 選單隱藏 + AI 無法觸發，只有知道指令名的人才能 /skill-name 召喚
- Q2（disable-model-invocation）：✅清空測試DB、✅發布到npm、✅強制merge main
- Q3（user-invocable: false）：✅API設計慣例30頁、✅舊版付款系統背景、✅公司技術債清單

---

## Step 4：設計一組高風險 Skill 的安全設定

### 情境

你們公司有以下三個 Skill 需要設計：

**Skill A：「刪除 30 天前的 S3 備份檔案」**

- 破壞性操作，刪了就找不回來
- 必須由管理員手動確認才能執行

**Skill B：「AWS 帳號結構與權限說明」**

- 背景參考資料，AI 在做基礎設施相關任務時自動參考
- 不需要出現在使用者的 Skill 選單

**Skill C：「自動重啟所有 Production 服務」**

- 破壞性操作，可能影響所有用戶
- 絕對不能被 AI 自動觸發

為三個 Skill 填入正確的 Front Matter 標籤：

```yaml
# Skill A
---
name: delete-s3-backups
description: （填入）
___________: ___________
---

# Skill B
---
name: aws-account-context
description: （填入）
___________: ___________
---

# Skill C
---
name: restart-production
description: （填入）
___________: ___________
___________: ___________   ← （這個需要兩個標籤）
---
```

### 實際結果

```yaml
# Skill A — 破壞性，管理員手動確認
name: delete-s3-backups
description: 刪除 30 天前的 S3 備份檔案。必須由管理員透過 /delete-s3-backups 顯式呼叫。
disable-model-invocation: true

# Skill B — 背景參考，選單隱藏
name: aws-account-context
description: AWS 帳號結構與 IAM 權限說明。AI 處理基礎設施任務時自動參考。
user-invocable: false

# Skill C — 最高風險，雙重鎖
name: restart-production
description: 重啟所有 Production 服務。僅限緊急情況，必須透過 /restart-production 顯式呼叫。
disable-model-invocation: true
user-invocable: false
```

---

## 本課重點

```
兩個安全 Front Matter 標籤：

  disable-model-invocation: true
    → AI 看得到這個 Skill 存在
    → 但絕對無法自動觸發
    → 必須人類手動輸入指令（/skill-name）才能執行
    → 適合：部署、資料庫清理、刪除操作等高風險行為

  user-invocable: false
    → AI 可以自動參考（當情境相關時）
    → 但對人類介面完全隱藏（Skill 選單看不到）
    → 適合：內部背景資料、API 慣例文件、技術債清單

安全設計三原則：
  高風險 = 加鎖（disable-model-invocation）
  背景知識 = 藏起來（user-invocable: false）
  不確定 = 兩個都加（雙重保護）

最小觸面原則：
  AI 能自動做的事越少，意外發生的機率越低
  把「AI 判斷」控制在唯讀、分析、建議範圍
  所有「寫入、刪除、部署」留給人類親自確認
```
