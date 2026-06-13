# 第 2 課演練記錄：@import 語法與 MonoRepo 向上遍歷

> 對應文件：
>
> - `code-中文/part1-design/claude-md/import-example/`
> - `code-中文/part1-design/claude-md/monorepo-example/`

## 課程目標

學會用 `@` 語法把 CLAUDE.md 模組化，避免單一檔案爆炸，
理解 MonoRepo 的向上遍歷機制讓不同子專案有不同規則，
體驗「前端 React 規範」和「後端 Go 規範」如何在同一個 repo 裡和平共存。

## 工作目錄

`code-中文/part1-design/demo/02-Import語法與MonoRepo/`

---

## Step 1：讀 import-example，理解 @import 語法

### 閱讀任務

打開以下兩個檔案：

- `claude-md/import-example/CLAUDE.md`
- `claude-md/import-example/docs/git-workflow.md`

回答：

1. CLAUDE.md 用什麼語法引入 git-workflow.md？

   答：

2. 如果 `git-workflow.md` 的 Commit 格式規定改了，我需要修改哪些檔案？

   答：

3. 如果不用 @import，而是把三個 docs/ 檔案的內容全部直接貼進 CLAUDE.md，
   估算大約會有幾行？（三個文件加起來）

   答：

4. 這種模組化設計有什麼具體好處？（至少說出兩個）

   答：

### 實際結果

（演練時填入）

---

## Step 2：探索 MonoRepo 的目錄結構

### 閱讀任務

打開並比較以下四個 CLAUDE.md 檔案：

- `claude-md/monorepo-example/CLAUDE.md`（根目錄）
- `claude-md/monorepo-example/packages/frontend/CLAUDE.md`
- `claude-md/monorepo-example/packages/backend/CLAUDE.md`
- `claude-md/monorepo-example/shared/CLAUDE.md`

### 填表

| 層級 | 放了什麼規則 | 這些規則適用於誰 |
|------|-----------|--------------|
| 根目錄 | | |
| frontend/ | | |
| backend/ | | |
| shared/ | | |

### 回答

1. 根目錄 CLAUDE.md 有一條「不可直接在 packages/ 底下建立檔案」。
   這條規則對哪些人適用？為什麼要放在根目錄而不是子目錄？

   答：

2. 前端用 React + Vite，後端用 Node.js + PostgreSQL。
   如果 AI 正在幫你修前端的 React 元件，它會看到 PostgreSQL 的資料庫規則嗎？

   答：

### 實際結果

（演練時填入）

---

## Step 3：理解向上遍歷（Scope 機制）

### 概念說明

當 AI 在 `packages/frontend/` 工作時，讀取順序：

```
1. packages/frontend/CLAUDE.md  ← 先讀（最具體，優先級最高）
        ↓
2. CLAUDE.md（根目錄）          ← 後讀（全域規則）
```

子目錄設定可以「覆蓋」根目錄設定。

### 思考練習

假設根目錄的 CLAUDE.md 寫：「縮排一律用 2 空格」，
但 `packages/backend/CLAUDE.md` 寫：「Go 程式碼用 gofmt（tab 縮排）」。

1. AI 在修後端 Go 程式碼時，會用什麼縮排？

   答：

2. AI 在修前端 React 程式碼時，會用什麼縮排？

   答：

3. 這種覆蓋機制類似程式設計裡的什麼概念？

   答：

### 設計練習

假設你管理一個 MonoRepo 包含三個子專案：

```
my-app/
├── CLAUDE.md               ← 全公司規則
├── web/                    ← Next.js 前端
│   └── CLAUDE.md
├── api/                    ← FastAPI 後端
│   └── CLAUDE.md
└── mobile/                 ← React Native
    └── CLAUDE.md
```

把以下規則分配到正確的 CLAUDE.md：

| 規則 | 應放在哪個 CLAUDE.md |
|------|-------------------|
| 「密碼絕對不能硬編碼在程式碼裡」 | |
| React Native 的元件使用 StyleSheet.create | |
| FastAPI 的 endpoint 必須加 Pydantic 驗證 | |
| Git commit 格式遵循 Conventional Commits | |
| Next.js 優先使用 Server Components | |

### 實際結果

（演練時填入）

---

## Step 4：觀察 templates/ 的設計邏輯

### 閱讀任務

打開 `claude-md/templates/nextjs.CLAUDE.md`，回答：

1. 這個模板包含哪些類別的規定？（列出主要分類）

   答：

2. 為什麼要有「環境變數」這一節（`NEXT_PUBLIC_` vs 不加前綴）？

   答：

3. 這個模板可以被哪些新專案直接套用？
   套用時需要改哪些地方？

   答：

### 實際結果

（演練時填入）

---

## 本課重點

```
@import 語法的三個好處：
  1. 模組化：每個規範放自己的檔案，獨立維護不互相干擾
  2. 精簡：CLAUDE.md 保持短小，只列目錄指引
  3. 選擇性載入：AI 只在需要時讀入特定文件

MonoRepo 向上遍歷的規律：
  最具體的子目錄 → 父目錄 → 根目錄
  子目錄規則可以覆蓋根目錄規則（類似程式語言的 scope）

設計原則：
  根目錄放「公司底線」（密碼、安全性、Commit 格式）
  子目錄放「團隊慣例」（語言規範、框架設定、縮排風格）
  模板放「可重用的起點」（Django / Go / Next.js 調校好的範本）
```
