# 第 7 課演練記錄：記憶刺青與專案模板

> 對應文件：
>
> - `code-中文/part1-design/claude-md/compact-instructions.md`
> - `code-中文/part1-design/claude-md/templates/nextjs.CLAUDE.md`
> - `code-中文/part1-design/claude-md/templates/django.CLAUDE.md`
> - `code-中文/part1-design/claude-md/templates/go.CLAUDE.md`

## 課程目標

理解上下文壓縮（context compression）是物理限制，不是 AI 的缺陷，
學會用 `compact instructions` 區塊控制壓縮時「絕對保留哪些資訊」，
掌握專案模板的設計邏輯，讓每個新專案從第一天就站在巨人肩膀上。

## 工作目錄

`code-中文/part1-design/demo/07-記憶刺青與專案模板/`

---

## Step 1：讀 compact-instructions.md，理解記憶刺青

### 閱讀任務

打開 `claude-md/compact-instructions.md`，回答：

1. Compact Instructions 被加在 CLAUDE.md 的哪個位置？

   答：

2. 它要求 Claude 在壓縮時必須保留哪些資訊？（列出所有項目）

   答：

3. 為什麼是「修改過的檔案完整路徑」而不是「所有已讀過的檔案」？

   答：

4. 如果沒有 Compact Instructions，長時間的除錯對話可能發生什麼問題？

   答：

5. 這個機制和「記憶拼圖主角把線索刺青在身上」的比喻，對應關係是什麼？

   | 比喻 | 技術概念 |
   |------|---------|
   | 主角每隔一段時間失憶 | |
   | 把最重要的線索刺青在身上 | |
   | 下一個週期的他看著刺青醒來 | |

### 實際結果

（演練時填入）

---

## Step 2：讀 PreCompact Hook 設計，理解主動保存機制

### 閱讀任務

繼續在 `compact-instructions.md` 裡，找到 PreCompact Hook 的設定：

```json
{
  "hooks": {
    "PreCompact": [...]
  }
}
```

回答：

1. PreCompact Hook 在什麼時間點觸發？

   答：

2. 它呼叫的 shell 腳本做了什麼？（看 save-session-state.sh 的內容）

   答：

3. 保存的資訊存到哪個檔案？

   答：

4. `compact instructions`（在 CLAUDE.md 裡告訴 AI 保留什麼）和 PreCompact Hook（在壓縮前主動保存）的差別是什麼？

   | 機制 | 執行者 | 時機 | 保存位置 |
   |------|--------|------|---------|
   | compact instructions | | | |
   | PreCompact Hook | | | |

### 實際結果

（演練時填入）

---

## Step 3：閱讀三個模板，找出共同結構

### 閱讀任務

打開以下三個模板並比較：

- `templates/nextjs.CLAUDE.md`
- `templates/django.CLAUDE.md`
- `templates/go.CLAUDE.md`

填入對比表：

| 共同章節 | Next.js 模板的內容 | Django 模板的內容 | Go 模板的內容 |
|---------|-----------------|----------------|-------------|
| 環境設定 / 啟動指令 | | | |
| 程式碼慣例 | | | |
| 測試指令 | | | |
| 特殊規定 | | | |

回答：

1. 三個模板都有「測試指令」這一節。為什麼連這個也要放進模板？

   答：

2. Next.js 模板有「環境變數」一節（NEXT_PUBLIC_ 前綴）。
   這解決了什麼常見的踩坑問題？

   答：

3. Go 模板特別強調「`_` 不可忽略 error」。
   這是 prohibited pattern（禁止模式）的概念嗎？

   答：

### 實際結果

（演練時填入）

---

## Step 4：設計你自己的專案 CLAUDE.md

### 綜合練習

根據本課七堂課學到的所有知識，為一個「FastAPI + React 全端專案」設計完整的 CLAUDE.md。

填入以下結構（每個 [] 替換成你的內容）：

```markdown
# [專案名稱] CLAUDE.md

## 專案概述
[一段話說明這個專案是什麼]

## 技術堆疊
- 後端：[...]
- 前端：[...]
- 資料庫：[...]

## 絕對事實（全域規則）
- [密碼 / 機密相關的規定]
- [關鍵檔案的路徑]
- [絕對不允許的操作]

## 啟動指令
[後端 / 前端的啟動指令]

## 引用的規則文件
- API 規範：@[路徑]
- 測試規範：@[路徑]

## Compact Instructions

壓縮 context 時，務必保留：
- [項目 1]
- [項目 2]
- [項目 3]
```

評估你的設計：

| 檢查項目 | 是否符合 |
|---------|---------|
| CLAUDE.md 只放「絕對事實」，沒有過多細節 | |
| 使用 @import 把大型規範文件分離 | |
| 有 Compact Instructions 區塊 | |
| 沒有把 Skill 的執行步驟放進來 | |
| 沒有把特定語言的細節規範放進來（那是 rules/ 的工作） | |

### 實際結果

（演練時填入）

---

## 本課重點

```
記憶刺青（Compact Instructions）：

  問題：對話超長 → Claude 被迫壓縮 → 關鍵進度被當雜訊丟棄
  解法：在 CLAUDE.md 加入 compact instructions 區塊
       告訴 Claude「壓縮時必須保留哪些資訊」

  必須保留的五類資訊：
    1. 修改過的檔案完整路徑
    2. 已執行的建置指令及其成功/失敗狀態
    3. 已發現的 bug 與預定修復方案
    4. 本次 session 做出的設計決策
    5. 未完成的任務

  進階：PreCompact Hook
    壓縮前主動執行 shell 腳本 → 把 git diff / git log 存進檔案
    雙重保障：AI 自己記 + 系統主動備份

專案模板的三個價值：
  1. 跳過冷啟動期（AI 不需要自己推測專案架構）
  2. 封裝血淚經驗（踩過的坑寫成 prohibited patterns）
  3. 標準化新專案（所有 Next.js 專案從同一個起點出發）

本課 7 堂課的核心哲學：
  關注點分離（Separation of Concerns）

  常駐記憶（CLAUDE.md） ↔ 條件載入（rules/） ↔ 隨需呼叫（skills/）
  點餐介面（description） ↔ 廚房實作（skill 主體）
  主代理（決策）         ↔ 子代理（繁重分析）
  靜態配置（CLAUDE.md）  ↔ 動態注入（!{command}）

  讓 AI 的算力 100% 集中在當下真正需要解決的問題上
```
