# Prompt 快取設計指南

## 提高快取命中率的 CLAUDE.md 設計原則

```markdown
<!-- CLAUDE.md 的穩定化模式 -->

## 穩定資訊（放在頂部）
- 專案概述
- 技術堆疊
- 程式碼撰寫慣例
- 固定的參考文件

## 易變資訊（放在底部）
- 目前工作狀態
- 近期變更
- TODO 清單
```

避免修改 CLAUDE.md 的頂部，讓該區段持續被快取。
把經常變動的資訊放在底部，使穩定的頂部區段
能維持較長的快取時間。

## 除錯：停用 Prompt 快取

```bash
# 停用所有模型的快取
export DISABLE_PROMPT_CACHING=1

# 逐模型停用
export DISABLE_PROMPT_CACHING_HAIKU=1
export DISABLE_PROMPT_CACHING_SONNET=1
export DISABLE_PROMPT_CACHING_OPUS=1
```

## 透過 Session 接續善用快取

```bash
# 從同一個專案目錄重新連線
claude --continue  # 接續先前的對話（最大化快取利用）
```

## 注意事項

- 快取並不會快取對話內容本身
- 被快取的是作為 context 送出的「固定部分」（CLAUDE.md、系統提示）
- 對話歷史每一輪都會改變，不會被快取
- DISABLE_PROMPT_CACHING 只接受 `1` 為有效值
