---
name: tech-debt-analysis
description: >
  掃描整個 codebase 找出技術債並產出優先級清單。
  適用於：技術債盤點、重構前評估、找 TODO/FIXME、函式太長、
  套件依賴缺漏、code quality review、重構計畫、清理技術負債。
  不觸發：一般 code review（用 code-reviewer）、資安掃描（用 security-audit）。
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
---

# 技術債分析 Skill

> 基於 kindle-20-65-automation-patterns Part 1 第 5 課設計

## 執行流程

### 搜尋範圍

- 主目錄：`src/`（含子目錄）
- 檔案類型：`.ts` / `.js` / `.py`
- 排除：`node_modules/`、`dist/`、`__pycache__/`、`.venv/`

如果 `src/` 不存在，改用當前目錄（`.`）。

### 偵測項目

#### 1. 函式過長（> 50 行）

```
Glob: src/**/*.{ts,js,py}
Read: 讀每個檔案，找函式/方法定義，計算行數
判斷：超過 50 行的函式記錄（函式名稱 + 行數 + 位置）
```

#### 2. TODO / FIXME 註解

```
Grep: pattern = "TODO|FIXME|HACK|XXX|TEMP"
範圍: src/**/*.{ts,js,py}
記錄: 檔案路徑:行號 + 完整註解文字
```

#### 3. 幽靈依賴（import 但未在 package.json 記錄）

```
Grep: 找所有 import 語句，提取套件名稱
Read: 讀取 package.json（dependencies + devDependencies）
比對: 找出 import 了但未在 package.json 中的套件
```

### 輸出格式

每筆技術債包含：

```
優先級: 高 / 中 / 低
類型: 函式過長 / TODO / FIXME / 幽靈依賴
位置: 檔案路徑:行號
說明: 一行描述（如「fetchUserData 函式 87 行，超過 50 行上限」）
建議: 一行具體建議（如「提取子函式，每個函式只做一件事」）
```

最後附上統計摘要：

```
技術債統計：
- 高優先：N 筆
- 中優先：N 筆
- 低優先：N 筆
總計：N 筆（依優先級排序）
```

### 優先級判斷標準

| 類型 | 優先級 | 原因 |
|------|--------|------|
| 函式 > 100 行 | 高 | 嚴重影響可讀性和可維護性 |
| 函式 51-100 行 | 中 | 建議重構但不緊急 |
| FIXME / HACK | 高 | 已知問題待修復 |
| TODO | 低 | 待辦事項，非緊急 |
| 幽靈依賴 | 高 | 可能在換環境時爆炸 |

## 紀律

- 子代理只讀不寫（`allowed-tools` 限制）
- 回傳給主對話的是摘要報告，不是原始檔案內容
- 找不到 src/ 時自動降級到當前目錄，不報錯
- 幽靈依賴比對只看 npm 套件（`import from 'xxx'`），不包含相對路徑 import
