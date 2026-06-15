# 第 6 課演練記錄：平行三維度審查

> 對應文件：`code-中文/part4-cicd/scripts/parallel-review.sh`

## 課程目標

理解為什麼用一個 AI 實例做「安全 + 品質 + 規範」三種審查會有「思維污染」問題，
學會用 `&` 背景執行 + `wait` + 暫存檔案的模式讓三個完全獨立的 AI 同時工作，
體驗平行審查在時間和品質上的雙重優勢。

## 工作目錄

`code-中文/part4-cicd/demo/06-平行三維度審查/`

---

## Step 1：閱讀 parallel-review.sh，理解平行模式

### 閱讀任務

打開 `scripts/parallel-review.sh`，回答：

1. 三個 Worker 各負責哪個維度的審查？

   | Worker | 審查維度 | 輸出檔案 |
   |--------|---------|---------|
   | Worker 1 | 安全性（command injection、未驗證輸入、exit code 處理） | `security.txt` |
   | Worker 2 | 程式碼品質（硬編碼路徑、錯誤處理、命名、重複邏輯） | `quality.txt` |
   | Worker 3 | 規範符合性（hook spec：exit 0/2、stop_hook_active、hookSpecificOutput JSON） | `spec.txt` |

2. `&` 符號的作用是什麼？如果去掉 `&`，三個審查會怎麼執行？

   答：`&` 讓指令在**背景執行**，Shell 不等它完成就繼續執行下一行（非阻塞）。去掉 `&` → 三個審查變成串行，總耗時 = 3 × 單一審查時間。

3. `REPORT_DIR=$(mktemp -d)` 建立了什麼？為什麼不直接把輸出寫到固定檔名？

   答：建立唯一的暫存目錄（如 `/tmp/tmp.xK3jQp`）。固定檔名會讓三個 Worker 同時寫入同一檔案，輸出交錯覆蓋造成亂碼。各自用獨立檔名（security/quality/spec.txt）完全隔離，`cat` 時再合併。

4. `wait $PID1 $PID2 $PID3` 的作用是什麼？如果不加 `wait` 直接讀結果會怎樣？

   答：`wait` 讓 Shell 阻塞直到三個 PID 全部完成才繼續。不加 `wait` → 直接 `cat` 時部分 Worker 可能還沒寫完，讀到空檔或截斷輸出。

5. 為什麼每個 Worker 的 prompt 末尾都有 `< /dev/null`？

   答：三個 Worker 在背景執行，若 Claude CLI 嘗試從 stdin 讀取，三個程序會競爭同一個 stdin 造成掛住或互搶。`< /dev/null` 關閉 stdin，確保背景程序不阻塞。

### 實際結果

讀取 parallel-review.sh 確認：3 Worker 分別負責安全/品質/規範，`&` 背景執行 + `mktemp -d` 隔離輸出 + `wait` 等齊的三元素設計。

---

## Step 2：計算時間優勢

### 思考練習

假設每個維度的審查平均需要 90 秒：

| 執行方式 | 總耗時 | 計算方式 |
|---------|--------|---------|
| 串行（一個接一個） | **270 秒** | 90 × 3 = 270 |
| 平行（`&` + `wait`） | **90 秒** | max(90, 90, 90) = 90 |
| 節省時間 | **180 秒（節省 2/3）** | 270 - 90 = 180 |

1. 如果是 10 個維度的審查，平行模式節省多少時間？

   答：串行 900 秒 vs 平行 90 秒，節省 810 秒（節省 90%）。維度越多，平行優勢越大。

2. 什麼情況下平行模式的時間優勢會消失？

   答：(1) 各維度耗時差異極大（總時間取決於最慢者）；(2) API Rate Limit 觸發限流；(3) 系統資源成為瓶頸（CPU/記憶體/磁碟 I/O 互搶）。

### 實際結果

計算確認：N 維度串行 vs 平行 = N 倍差距，10 維度節省 90% 時間。

---

## Step 3：實際執行 parallel-review.sh

### 指令

```bash
cd c:/Users/user/workspace/kindle-20-65-automation-patterns
bash code-中文/part4-cicd/scripts/parallel-review.sh
```

### 觀察重點

1. 三個 Worker 是同時啟動的嗎？（觀察啟動訊息的時間戳）

   答：**是**。三個 `&` 指令幾乎同時發出，間隔 < 100ms，三個程序立刻並行。

2. 哪個 Worker 最先完成？哪個最慢？

   答：通常 Worker 3（規範符合性）最快（只需 PASS/FAIL）；Worker 2（品質）最慢（需逐一比對細節）。實際順序每次可能不同。

3. 三個報告的格式一致嗎？（安全性、品質、規範符合性）

   答：**格式不同**，因為各 prompt 要求不同：安全性用 Critical/High/Medium + file:line；品質用 Critical/Warning/Suggestion；規範用 PASS/FAIL per hook file。

4. 整個過程耗時多久（從啟動到全部完成）？

   答：約 60-120 秒（取決於 API 負載），串行同樣三任務約需 180-360 秒。

### 實際結果

（演練時填入）

---

## Step 4：理解「思維污染」問題

### 思考問題

1. 為什麼法院案件不讓同一位法官同時扮演辯護律師和檢察官？這和三維度審查有什麼關係？

   答：**角色混同 = 判斷受先前立場汙染**。同一個 Claude 實例先做安全審查發現問題後，再做品質審查時已有先入為主偏見，可能鬆化或強化標準。獨立實例 = 每位「法官」只看自己的案卷，無跨角色汙染。

2. 在哪些業務場景中，「獨立評估」比「一個全知的評估者」更重要？

   答：財務審計（簽帳人與審計人分離）、醫療第二意見（不先看第一位診斷）、A/B 測試評分（評分者不知道是 A/B）、法規合規 + 安全審查（不讓合規去幫安全找理由）。

### 實際結果

理解思維污染本質：同一 context 的先後偏差 vs 獨立 context 的對等判斷。

---

## Step 5：設計自己的平行審查

### 練習

「PR 提交品質檢查」三維度平行審查設計：

```bash
REPORT_DIR=$(mktemp -d)

# Worker 1：檢查 Commit 訊息格式
claude -p "Review the latest git commit message in this repo.
  Check: (1) follows Conventional Commits format <type>(<scope>): <desc>,
  (2) type is one of feat/fix/docs/refactor/test/chore,
  (3) description is under 72 chars and in imperative mood.
  Report PASS or FAIL with specific reason." \
  --allowedTools "Bash(git log *)" < /dev/null > "$REPORT_DIR/commit.txt" &
PID1=$!

# Worker 2：檢查新增檔案有無硬編碼路徑或機密資訊
claude -p "Review files changed in the latest git commit.
  Find: (1) hardcoded absolute paths (/c/Users/... or C:/Users/...),
  (2) hardcoded API keys or tokens (strings matching [A-Za-z0-9]{32,}),
  (3) passwords or secrets in plain text.
  Report each finding as Critical/High with file:line." \
  --allowedTools "Bash(git diff *),Read,Grep" < /dev/null > "$REPORT_DIR/secrets.txt" &
PID2=$!

# Worker 3：檢查測試覆蓋率
claude -p "Review files changed in the latest git commit.
  For each .py or .js file added or modified,
  check if a corresponding test_*.py or *.test.js file exists.
  Report COVERED or MISSING per source file." \
  --allowedTools "Bash(git diff *),Glob" < /dev/null > "$REPORT_DIR/tests.txt" &
PID3=$!

wait $PID1 $PID2 $PID3

echo "=== Commit 格式 ===" && cat "$REPORT_DIR/commit.txt"
echo "=== 機密掃描 ===" && cat "$REPORT_DIR/secrets.txt"
echo "=== 測試覆蓋 ===" && cat "$REPORT_DIR/tests.txt"
```

設計要點：三個 Worker prompt 完全獨立（無「根據前面結果」）；`--allowedTools` 依各自需要精確設定；輸出格式各異但符合各維度需求。

### 實際結果

（演練時填入）

---

## 本課重點

```
平行審查的三元素：
  &         → 背景執行（非阻塞，立刻啟動下一個）
  wait      → 等全部完成後才繼續（確保結果齊全）
  mktemp -d → 隔離輸出（避免多個程序同時寫同一個檔案造成亂碼）

獨立實例的優勢：
  無思維污染（Worker 1 的發現不影響 Worker 2 的判斷）
  對等審查（三個維度對等重要，沒有先後偏差）
  平行節省時間（N 個維度的時間 = 1 個維度的時間）

設計原則：
  每個維度的 prompt 要完整且獨立（不能說「根據前面的結果」）
  每個 Worker 的 --allowedTools 可以一樣（都是唯讀）
  先 wait 再整合輸出（不要在 wait 之前 cat 可能還沒寫完的檔案）
```
