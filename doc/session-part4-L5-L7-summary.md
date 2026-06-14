# Session 摘要：Part 4 第 5-7 課

日期：2026-06-15

## 完成進度

| 課程 | 主題 | commit |
|------|------|--------|
| Part 4 第 5 課 | Plan Mode 安全護欄 | 7ae29bf |
| Part 4 第 6 課 | 平行三維度審查 | 82a131e |
| Part 4 第 6 課（腳本） | pr-quality-check.sh | a5da8a5 |
| Part 4 第 7 課 | 完整 CI/CD Pipeline | 441f4bf |

## 各課重點

### 第 5 課：Plan Mode 安全護欄

- `--permission-mode plan` = 系統層硬護欄，Write/Edit 工具呼叫一律被 harness 攔截
- 軟護欄（prompt 說「不要改」）vs 硬護欄（Plan Mode）的本質差異
- 實驗驗證：故意要求修改檔案，git diff 輸出為空，硬護欄生效
- API Key 洩漏後：Plan Mode 保護程式碼完整性，但無法防讀取洩漏

### 第 6 課：平行三維度審查

- 平行三元素：`&`（背景執行）+ `wait`（等齊）+ `mktemp -d`（輸出隔離）
- 思維污染：同一 Claude 實例依序做多種審查，先做的結果汙染後做的判斷
- 時間優勢：N 維度串行 vs 平行 = N 倍差距（10 維度節省 90%）
- `< /dev/null` 在背景程序必備：防多程序競爭 stdin
- Step 5 演練腳本：`pr-quality-check.sh`（Commit 格式 + 機密掃描 + 測試覆蓋率）

### 第 7 課：完整 CI/CD Pipeline

- 完整流程：PR 開啟 → AI 審查留言 → 測試失敗 → AI 修復 → 開 PR → 人工審核
- 三個鐵律：
  1. AI 永遠不直接 push main（開 PR 等人類決定）
  2. `[skip actions]` 防無限觸發迴圈
  3. 最小化 AI 修改範圍（只修測試失敗的問題）
- 六課技術整合對應表（各技術在 Pipeline 中的角色）
- GitHub Secrets 設定位置：Settings → Secrets and variables → Actions

## 本 session commit 列表

```
441f4bf 存檔 Part4 第 7 課：完整 CI/CD Pipeline
a5da8a5 新增 Part4 第 6 課 Step5 演練腳本：pr-quality-check.sh
82a131e 存檔 Part4 第 6 課：平行三維度審查演練
7ae29bf 存檔 Part4 第 5 課：Plan Mode 安全護欄演練
```

## 下次繼續

確認 Part 2 Hooks 是否已建立互動演練課程，若無則新建。
