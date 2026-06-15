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

### 三個用量資料管道

| 管道 | 方式 |
|------|------|
| 1 | `claude -p "..." --output-format json \| jq '.usage'`（Session 層級，即時數字） |
| 2 | 讀取 transcript：`~/.claude/projects/*/transcripts/*.jsonl`（逐字稿分析） |
| 3 | `estimate-cost.sh` 估算腳本（解析 jsonl，粗估 input + output 費用） |

### 四個 Token 欄位

| JSON 欄位 | 意思 |
|-----------|------|
| `input_tokens` | 本次送出的完整 context（prompt + 歷史 + 工具呼叫結果） |
| `output_tokens` | AI 實際生成的文字 |
| `cache_read_input_tokens` | 命中 Prompt Cache 的 token（費率約為 input 的 10%） |
| `cache_creation_input_tokens` | 首次建立快取的 token（一次性成本，略高於 input 計費） |

### 成本估算腳本定價

Sonnet 4 兩個定價：

- Input：**$3 / 百萬 token**
- Output：**$15 / 百萬 token**

（腳本程式碼：`INPUT_COST=$INPUT * 3 / 1000000`、`OUTPUT_COST=$OUTPUT * 15 / 1000000`）

### 實際結果

讀取 cost-monitoring.md 確認：三個管道（CLI json / transcript / 估算腳本）、四種 token 欄位（input / output / cache_read / cache_creation）、Sonnet 4 定價 $3/$15 per million。

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

   典型範圍：500–2000（視 CLAUDE.md 長度和 session 歷史而定）

2. `output_tokens` 是多少？

   典型範圍：50–200（一句話解釋不會太長）

3. `input_tokens` 大約是 `output_tokens` 的幾倍？

   通常是 5–20 倍——即使只問「一句話解釋 Token」，整個 CLAUDE.md 和系統 context 都被帶進去了。

### 反直覺發現

> Input 往往是 Output 的 3–10 倍。你送出去的「問題」比 AI 回答的「答案」還貴——
> 因為你其實是把整個對話歷史 + CLAUDE.md + 所有 context 一起送出去的。

### 實際結果

執行指令觀察 input/output 比例，確認 input 遠多於 output。核心洞察：「你的問題」只佔 input 的一小部分，大部分是 context 帶入的固定成本。

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

   答：**2800 字**。規律是每輪 +300（前一輪 AI 回 200 + 你新問 100），等差數列：100, 400, 700, ..., 第10輪 = 100 + 9×300 = **2800 字**。

2. 10 輪累計的 Input 總量是多少？（等差數列）

   答：**14,500 字**。等差數列 (首項100 + 末項2800) × 10 / 2 = 14,500 字。而 10 輪的 Output 總量只有 10×200 = 2000 字——Input 是 Output 的 **7.25 倍**。

3. 所以「叫 AI 回答短一點」能省多少成本？為什麼省不了 Input？

   答：「叫 AI 回答短一點」只省 Output——Output 每輪 200→100 字，10 輪省 1000 字，只佔總量（16,500字）的 **6%**。  

   Input 省不了，因為 **Input = 所有歷史對話的累積**。你的每一輪問題在後面每一輪都繼續被帶入——Input 隨輪次等差增長，這是無法靠「AI 說短一點」改善的。真正有效的省錢方法：**壓縮對話歷史**（`/compact`）或**善用 Prompt Cache**（讓重複的 CLAUDE.md 部分走快取折扣）。

### 實際結果

完成迴轉壽司計費計算：第10輪 Input = 2800字，10輪累計 Input = 14,500字 vs Output = 2000字。核心洞察：省 Output 杯水車薪，真正的成本在累積的 Input。

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
