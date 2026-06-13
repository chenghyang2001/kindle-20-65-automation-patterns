# 第 2 課演練記錄：notify.sh

> 範例檔：`notification/notify.sh`
> demo 腳本：`notify-demo.sh`（唯一修改：Slack 回應從 `> /dev/null` 丟掉改成 `-o slack-response.json` 存檔）
> 事件：`Notification`（Claude 需要使用者注意時觸發）｜ 難度：⭐
> 主題：AI 等你輸入時主動通知你 + 優雅降級

---

## 核心觀念

- **優雅降級**：通知是「有了更好」的輔助功能，失敗也絕不拖垮主流程（`2>/dev/null` + `-n` 前置檢查）
- 測試用 httpbin.org 當假 webhook（你 POST 什麼它就反射回來），讓通知內容看得見

---

## Step 1：什麼都不設定，直接餵 JSON — 體驗優雅降級

**下的命令：**

```bash
unset SLACK_WEBHOOK_URL
echo '{"notification_type": "permission_request"}' | bash demo/notify-demo.sh
echo $?
```

**目的：** 在 Windows（無 osascript）+ 沒設 Slack 的環境，看 hook 怎麼「安靜失敗」。

**預期效果：** 畫面安靜 + exit 0，demo 目錄不產生 slack-response.json。

**實際驗證結果：** ✅ exit 0、無輸出、`ls demo/` 只有腳本本身。內部兩次失敗都被吞掉：

- `osascript` 在 Windows 不存在 → `2>/dev/null` 丟掉錯誤
- Slack 沒設 → `if [ -n "$SLACK_WEBHOOK" ]` 整段跳過（連 curl 都沒執行）

---

## Step 2：設定假 Slack（httpbin），看通知真的發出去

**下的命令：**

```bash
export SLACK_WEBHOOK_URL="https://httpbin.org/post"
echo '{"notification_type": "permission_request"}' | bash demo/notify-demo.sh
cat demo/slack-response.json
```

**目的：** 證明 hook 真的對 webhook 發出 HTTP POST，且通知文字組裝正確。

**預期效果：** 回應檔含 `"url": "https://httpbin.org/post"` + 反射回來的通知內容。

**實際驗證結果：** ✅ POST 成功，但 **活捉 cp950 編碼亂碼 bug**：

- 回應的 base64 解碼後中文變 `a5bf a662 b5a5...`（Big5 / cp950，不是 UTF-8）
- 原因：Git Bash 預設 cp950，curl 送中文 JSON 沒轉 UTF-8
- 對應全域規則「curl 送 JSON（Git Bash）→ 改用 Python urllib」的現場直擊
- 教訓：**「能跑」≠「跑對」，exit 0 ≠ 內容正確**

---

## Step 3：餵缺欄位的 JSON，看 `// "unknown"` 預設值生效

**下的命令：**

```bash
export SLACK_WEBHOOK_URL="https://httpbin.org/post"
echo '{}' | bash demo/notify-demo.sh
# 用 python base64 解碼回應檔的通知文字
```

**目的：** 對比第 1 課的 `null` 垃圾值，看預設值機制怎麼攔下空欄位。

**預期效果：** 通知文字從 `permission_request` 變成 `unknown`。

**實際驗證結果：** ✅ 通知文字 = `"Claude Code: unknown - ..."`。`jq -r '.notification_type // "unknown"'` 的 `//` 把缺欄位頂成預設值。中文部分仍亂碼（編碼坑與預設值是兩件獨立的事，要分開處理）。

---

## Step 4（加碼）：Windows 版通知長什麼樣

**下的命令：**

```bash
# 用 PowerShell EncodedCommand（base64 + UTF-16LE）傳中文，避開 cp950 坑
ENCODED=$(python -c "...base64.b64encode(ps.encode('utf-16-le'))...")
powershell -EncodedCommand "$ENCODED"
```

**目的：** 原版 macOS 通知看不到，用 PowerShell 彈真的 Windows 通知視窗示範移植。

**預期效果：** 螢幕彈出「Claude Code 通知」對話框，按 OK 回傳 `OK`。

**實際驗證結果：** ✅ 視窗彈出、按 OK 回傳 `OK`。另 **活捉 CLIXML 輸出污染**：

- 輸出開頭混入 `#< CLIXML <Objs Version=...>` 序列化噪音
- 這就是 Windows 版的「輸出污染」（對應 macOS 的 .bashrc 歡迎訊息污染，Pattern 22）
- 若這段 PowerShell 包在 hook 裡，這串噪音會讓 Claude 解析 stdout JSON 崩潰
- 解法同 .bashrc 污染：手動 pipe 測試、肉眼確認輸出純淨

---

## 帶走的重點

| 概念 | 步驟 |
|------|------|
| 優雅降級：輔助功能失敗不拖垮主流程 | Step 1 |
| 通知真發出去 + **cp950 編碼亂碼 bug** | Step 2 |
| `// "unknown"` 預設值 vs 第 1 課 `null` 垃圾值 | Step 3 |
| Windows 通知移植 + **CLIXML 輸出污染** | Step 4 |

**產出物：** `notify-demo.sh`、`slack-response.json`
**野生 bug 收穫：** cp950 亂碼、CLIXML 污染（真實環境才看得到）
