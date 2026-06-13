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

（演練時填入）

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

（演練時填入）

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

（演練時填入）

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

（演練時填入）

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
