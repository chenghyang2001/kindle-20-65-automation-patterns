# 第 3 課演練記錄：Skill 描述陷阱

> 對應文件：
>
> - `code-中文/part1-design/skills/good-description/SKILL.md`
> - `code-中文/part1-design/skills/good-description/examples/bad-example.md`
> - `code-中文/part1-design/skills/good-description/examples/good-example.md`

## 課程目標

理解 Skill 的 `description` 欄位是「語意選擇器」而非「執行手冊」，
學會區分「這個 Skill 是什麼 / 什麼時候用」和「這個 Skill 怎麼做」，
掌握用同義詞增加語意命中面積的技巧。

## 工作目錄

`code-中文/part1-design/demo/03-Skill描述陷阱/`

---

## Step 1：對比 bad vs good 描述，找出關鍵差異

### 閱讀任務

打開這兩個檔案並仔細比較：

- `skills/good-description/examples/bad-example.md`（錯誤示範）
- `skills/good-description/SKILL.md`（正確示範，用 deploy skill）

填入對比表：

| 比較維度 | bad-example 的 description | good-example 的 description |
|---------|--------------------------|---------------------------|
| 長度（行數） | | |
| 內容類型 | | |
| 有沒有觸發情境 | | |
| 有沒有同義詞 | | |

### 回答

1. bad-example 的 description 寫了什麼類型的內容？

   答：

2. 當 AI 讀完 bad-example 的 description，它可能產生什麼錯覺？

   答：

3. good-example 的 description 只有兩件事，是哪兩件事？

   答：

### 實際結果

| 比較維度 | bad-example | good-example（SKILL.md） |
|---------|------------|------------------------|
| 長度（行數） | 6 行（含 5 步驟） | 2 行 |
| 內容類型 | 執行步驟（怎麼做） | 定義 + 觸發情境（是什麼 + 什麼時候用）|
| 有沒有觸發情境 | 沒有 | 有（生產環境發布、緊急部署）|
| 有沒有同義詞 | 沒有 | 有（生產環境發布 / 緊急部署）|

- Q1：bad-example 寫了「執行步驟」（npm test / build / push / 驗證 / Slack），把 Skill 主體的內容放進了 description
- Q2：AI 讀完後產生錯覺「我已經知道完整步驟了」→ 跳過 Skill 主體直接照 description 執行
- Q3：good-example 只說兩件事：①做什麼（部署到生產環境）②什麼時候用（顯式呼叫 + 適用情境）

---

## Step 2：理解「語意向量匹配」機制

### 概念說明

AI 匹配 Skill 的機制：

```
使用者說：「幫我看一下這包 Code 能不能 Merge」
        ↓
轉成數學向量（embedding）
        ↓
與每個 Skill 的 description 向量計算相似度
        ↓
相似度最高的 Skill 被喚醒

如果 description 是「步驟 1: 跑測試；步驟 2: build；步驟 3: 部署...」
→ 這個描述的向量代表「部署操作步驟」
→ 不代表「程式碼審查」
→ 使用者說「幫我審查程式碼」時，這個 Skill 的向量距離很遠
→ Skill 被錯過
```

### 思考練習

1. 以下哪些說法在語意上與「PR 審查」相近？
   （勾選所有你認為向量距離近的說法）

   - [ ] 幫我看一下這包 Code 能不能 Merge
   - [ ] 審查 Pull Request
   - [ ] Code Review 一下
   - [ ] 合併前幫我檢查
   - [ ] 幫我部署到正式環境
   - [ ] 這個 PR 有什麼問題嗎
   - [ ] Review 一下程式碼品質

2. 如果 description 只寫「執行程式碼審查」，上面勾選的說法有哪些可能被漏掉？

   答：

3. 所以 description 要包含同義詞的原因是什麼？

   答：

### 實際結果

- 與「PR 審查」語意相近：✅幫我看 Code 能不能 Merge / ✅審查 Pull Request / ✅Code Review / ✅合併前幫我檢查 / ✅這個 PR 有什麼問題 / ✅Review 程式碼品質；❌部署到正式環境
- 只寫「執行程式碼審查」可能漏掉：「能不能 Merge」「合併前檢查」「PR 有什麼問題」（這些說法向量距離較遠）
- 同義詞原因：增加「語意表面積」，讓向量匹配有更多錨點，使用者任何說法都能命中正確 Skill

---

## Step 3：把 bad-example 改寫成 good-example

### 練習

參考 good-example 的格式，把 bad-example 的 description 改寫：

**原始（bad）**：

```yaml
description: >
  部署 skill。
  1. 執行 npm test 並確認所有測試通過
  2. 用 npm run build 建置
  3. 用 git push origin main 部署
  4. 在 https://app.example.com 驗證部署
  5. 在 Slack #deployments 頻道發佈通知
```

**你的改寫版（good）**：

```yaml
description: >
  （填入你的改寫）
```

改寫原則：

- 第一句話說「做什麼」（1 行以內）
- 第二句話說「什麼時候用」（觸發情境）
- 加入同義詞（使用者可能的各種說法）
- 不寫任何步驟、不寫指令

### 實際結果

改寫版（good）：

```yaml
description: >
  發布新版本到生產環境。
  適用於：deploy、上線、發布正式版、推到 main、緊急熱修上線。
  必須透過 /deploy 顯式呼叫，不自動觸發。
```

關鍵改動：移除 5 個執行步驟、加觸發情境、加同義詞、加「不自動觸發」防誤觸

---

## Step 4：設計三個新 Skill 的 description

### 練習

為以下三個假想的 Skill 寫出正確格式的 description：

**Skill A：自動生成 Release Notes**
（功能：讀 git log，整理成 Changelog 格式）

```yaml
description: >
  （你的答案）
```

**Skill B：資料庫 Schema 分析**
（功能：分析現有 DB 結構，找出效能瓶頸和缺少的 index）

```yaml
description: >
  （你的答案）
```

**Skill C：API 文件生成**
（功能：從程式碼的 JSDoc 自動產生 OpenAPI 文件）

```yaml
description: >
  （你的答案）
```

### 實際結果

**Skill A：自動生成 Release Notes**

```yaml
description: >
  從 git log 自動生成 Changelog 和 Release Notes。
  適用於：版本發布前整理變更、生成 CHANGELOG、寫 release 說明、
  幫我整理這次版本改了什麼、v1.2.0 有哪些更新。
```

**Skill B：資料庫 Schema 分析**

```yaml
description: >
  分析資料庫結構，找出效能瓶頸和缺少的 index。
  適用於：DB 跑很慢、查詢優化、schema review、
  幫我看 index 夠不夠、資料庫設計有什麼問題、缺哪些索引。
```

**Skill C：API 文件生成**

```yaml
description: >
  從程式碼的 JSDoc 自動產生 OpenAPI / Swagger 文件。
  適用於：生成 API 文件、更新 swagger、JSDoc 轉文件、
  幫我把程式碼的註解變成 API spec、輸出 openapi.yaml。
```

---

## 本課重點

```
description 欄位的雙重身份：

  它是「點餐菜單」不是「廚房食譜」
    → 菜單只告訴你有什麼菜、什麼時候點
    → 實際的烹飪步驟在 Skill 主體裡

  它是「語意選擇器」不是「執行手冊」
    → AI 用向量相似度決定要不要觸發
    → 執行步驟寫在 description 裡 = AI 以為自己已經知道怎麼做了 = 跳過 Skill

正確格式（兩行公式）：
  行 1：【做什麼】一句話說明（動詞 + 結果）
  行 2：【什麼時候用】觸發情境 + 同義詞清單

同義詞的重要性：
  「PR 審查」「Code Review」「合併前檢查」「看一下能不能 Merge」
  這些都應該命中同一個 Skill
  description 要提供足夠的「語意表面積」讓向量匹配成功
```
