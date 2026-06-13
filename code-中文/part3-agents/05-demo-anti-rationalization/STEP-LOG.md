# 第 5 課演練記錄：反理由化防護

> 對應文件：`docs/rationalization-prevention.md`

## 課程目標

理解 AI 的 12 種迴避行為（理由化模式），
學會在 agent 的 system prompt 中嵌入防護條款，
讓 agent「不找藉口、直接執行」。

## 工作目錄

`code-中文/part3-agents/demo-anti-rationalization/`

---

## Step 1：認識 12 種理由化模式

### 指令

```bash
cat ../docs/rationalization-prevention.md
```

### 填入「最常見的 3 種」（演練時填入）

1. ___
2. ___
3. ___

---

## Step 2：比較有防護 vs 無防護的 agent

### 無防護版（一般 agent）

```markdown
---
name: implementation-agent
description: 實作專家。實作任務時主動使用。
tools: Read, Write, Edit, Bash, Grep, Glob
---

請完成被交付的任務。
```

### 有防護版（加入反理由化條款）

```markdown
---
name: implementation-agent-safe
description: 實作專家。實作任務時主動使用。
tools: Read, Write, Edit, Bash, Grep, Glob
---

## 行為原則

完成被交付的任務。以下是理由化行為，直接跳過：

- 「做不到」→ 轉換成「要怎麼做到？」
- 「可能有危險」→ 執行改動並回報疑慮
- 「超出範圍」→ 執行指示範圍，再列出額外工作
- 「不清楚」→ 用最合理的解讀推進，說明假設
- 「發生錯誤了」→ 分析錯誤、嘗試解法，再回報

無法完成任務時：**回報已嘗試的步驟和具體阻礙**，
不可僅說「很難做到」或「需要更多資訊」。
```

---

## Step 3：建立 implementation-agent-safe.md

### 建立指令

```bash
cat > demo-anti-rationalization/implementation-agent-safe.md << 'EOF'
（填入有防護版內容）
EOF
```

### 實際結果

（演練時填入）

---

## Step 4：模擬測試（用 claude -p 測試迴避行為）

### 場景：給 agent 一個「看起來有點難」的任務

```bash
echo "請修改 nonexistent-file.py 加入 logging 功能" \
  | claude -p --system "$(cat implementation-agent-safe.md | tail -n +7)"
```

### 預期差異

| 無防護 agent | 有防護 agent |
|-------------|-------------|
| 「檔案不存在，無法繼續」 | 「嘗試：1) 用 Glob 尋找... 2) 確認路徑... 回報：找不到 nonexistent-file.py，可能路徑是...」 |

### 實際結果

（演練時填入）

---

## 本課重點

| 概念 | 說明 |
|------|------|
| 理由化行為 | AI 遇困難時找藉口停工，不是真的做不到 |
| 防護目的 | 不是要 AI「什麼都照做」，是阻斷「技術上可行但找藉口不做」 |
| 安全限制仍有效 | tools 白名單 + permissionMode 依然守住邊界 |
| 嵌入位置 | agent 的 system prompt（frontmatter 之後的內文） |
