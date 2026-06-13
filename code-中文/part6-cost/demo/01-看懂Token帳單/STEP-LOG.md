# 第 1 課演練記錄：看懂 Token 帳單

> 對應文件：`code-中文/part6-cost/cost-monitoring.md`

## 課程目標

理解 Token 成本的真正結構：為什麼 Input 比 Output 貴、
什麼是 cache_read_input_tokens、如何從 Claude Code 拿到用量數字，
建立「看帳單」的基本能力，才能知道錢花到哪裡。

## 工作目錄

`code-中文/part6-cost/demo/01-看懂Token帳單/`

---

## Step 1：閱讀成本監控指南，建立基礎概念

### 閱讀任務

打開 `cost-monitoring.md`，回答：

1. Claude Code 透過哪三個管道揭露成本資料？

   | 管道 | 方式 |
   |------|------|
   | 1 | |
   | 2 | |
   | 3 | |

2. 在 `--output-format json` 的輸出中，有四個 token 欄位，分別代表什麼？

   | JSON 欄位 | 意思 |
   |-----------|------|
   | `input_tokens` | |
   | `output_tokens` | |
   | `cache_read_input_tokens` | |
   | `cache_creation_input_tokens` | |

3. 成本估算腳本用 Sonnet 4 的哪兩個定價來計算？

   答：

### 實際結果

（演練時填入）

---

## Step 2：執行用量查詢指令

### 指令

在終端機執行（用一個簡單的 claude -p 問題來觀察用量）：

```bash
claude -p "用一句話解釋什麼是 Token" --output-format json | python -c "
import json, sys
data = json.load(sys.stdin)
usage = data.get('usage', {})
print('=== Token 用量 ===')
for k, v in usage.items():
    print(f'{k}: {v}')
"
```

### 觀察重點

執行後回答：

1. `input_tokens` 是多少？
2. `output_tokens` 是多少？
3. `input_tokens` 大約是 `output_tokens` 的幾倍？

### 反直覺發現

> Input 往往是 Output 的 3–10 倍。你送出去的「問題」比 AI 回答的「答案」還貴——
> 因為你其實是把整個對話歷史 + CLAUDE.md + 所有 context 一起送出去的。

### 實際結果

（演練時填入）

---

## Step 3：理解「迴轉壽司計費」

### 思考練習

假設你和 AI 對話了 10 輪，每輪問 100 字、AI 回 200 字：

| 輪次 | 你送出的 Input | AI 產出的 Output |
|------|--------------|-----------------|
| 第 1 輪 | 100 字 | 200 字 |
| 第 2 輪 | 100 + 200 + 100 = **400 字** | 200 字 |
| 第 3 輪 | 400 + 200 + 100 = **700 字** | 200 字 |
| 第 10 輪 | ??? 字 | 200 字 |

回答：

1. 第 10 輪你實際送出多少字的 Input？（算算看）

   答：

2. 10 輪累計的 Input 總量是多少？（等差數列）

   答：

3. 所以「叫 AI 回答短一點」能省多少成本？為什麼省不了 Input？

   答：

### 實際結果

（演練時填入）

---

## 本課重點

```
Token 成本的三大事實：
1. Input 佔成本 60-80%（Output 只佔 15-30%）
2. 每輪對話的 Input = 當輪問題 + 所有歷史記錄（迴轉壽司計費）
3. cache_read_input_tokens 是你的「打折票」——快取命中才有折扣
```

| 欄位 | 代表 | 策略 |
|------|------|------|
| `input_tokens` | 完整送出的 token | 減少歷史長度（/compact） |
| `cache_read_input_tokens` | 快取命中的 token（打9折） | 讓 CLAUDE.md 保持穩定 |
| `output_tokens` | AI 產出的 token | 省不了多少，不是重點 |
