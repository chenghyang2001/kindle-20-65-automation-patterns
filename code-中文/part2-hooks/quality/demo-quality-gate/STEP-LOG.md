# 第 9 課演練記錄：quality-gate.sh

> 範例檔：`quality/quality-gate.sh`（Stop event 品質守衛）

## 課程目標

學習如何用 Stop hook 在 Claude Code **每次停止回應前**自動執行品質檢查，
並透過 `stop_hook_active` 旗標避免 hook 呼叫自身造成的**無限迴圈**。

## 工作目錄

`code-中文/part2-hooks/quality/demo-quality-gate/`

---

## Step 1：測試無限迴圈煞車（stop_hook_active = true）

### 指令

```bash
cd <專案根目錄>
echo '{"stop_hook_active": true}' | bash "code-中文/part2-hooks/quality/demo-quality-gate/quality-gate-demo.sh"
echo "exit_code=$?"
```

### 目的

驗證 Stop hook 的**自我保護機制**：
當 Claude Code 本身因為呼叫 Stop hook 而觸發另一個 Stop 事件時，
`stop_hook_active` 會被設為 `true`，腳本應立即 `exit 0` 不做任何檢查。

### 預期效果

- **stdout 完全空白**（不輸出任何 JSON）
- exit code = 0

### 實際驗證結果 ✅

```
exit_code=0
```

stdout 為空，煞車機制正確生效。

---

## Step 2：乾淨狀態應安靜通過（stop_hook_active = false）

### 指令

```bash
cd <專案根目錄>
git diff --name-only && git diff --name-only --cached
echo '{"stop_hook_active": false}' | bash "code-中文/part2-hooks/quality/demo-quality-gate/quality-gate-demo.sh"
echo "exit_code=$?"
```

### 目的

驗證在**無任何 staged/unstaged 變更**的乾淨狀態下，
品質門全部通過，hook 安靜退出（不阻擋 Claude Code）。

### 預期效果

- `git diff` 無輸出（沒有未追蹤的變更）
- **stdout 完全空白**
- exit code = 0

### 實際驗證結果 ✅

```
(no staged/unstaged changes to tracked files)
exit_code=0
```

無 staged/unstaged 變更、無 `src/` 底下的 TODO → 品質門全過，安靜通過。

---

## Step 3：製造 staged 變更，驗證 block JSON 輸出

### 指令

```bash
cd <專案根目錄>
# 製造 staged 變更
echo "# quality-gate demo test file" > quality-gate-test.tmp
git add quality-gate-test.tmp
git diff --name-only --cached    # 確認 staged

# 執行 hook
echo '{"stop_hook_active": false}' | bash "code-中文/part2-hooks/quality/demo-quality-gate/quality-gate-demo.sh"
echo "exit_code=$?"
```

### 目的

驗證當有**未 commit 的 staged 變更**時，
hook 正確輸出 `decision: block` 的 JSON，告知 Claude Code 停止並顯示原因。

### 預期效果

```json
{
  "decision": "block",
  "reason": "1. 偵測到未 commit 的變更"
}
```

### 實際驗證結果 ✅

```
quality-gate-test.tmp

{
  "decision": "block",
  "reason": "1. 偵測到未 commit 的變更"
}
exit_code=0
```

品質門偵測到問題，輸出帶編號清單的 block JSON。Claude Code 收到後會停止並把 reason 顯示給使用者。

---

## Step 4：同樣有問題但 stop_hook_active=true → 煞車介入

### 指令

```bash
cd <專案根目錄>
# 此時 quality-gate-test.tmp 仍是 staged 狀態
echo '{"stop_hook_active": true}' | bash "code-中文/part2-hooks/quality/demo-quality-gate/quality-gate-demo.sh"
echo "exit_code=$?"

# 清理：還原並刪除測試檔
git reset HEAD quality-gate-test.tmp
rm quality-gate-test.tmp
```

### 目的

對比 Step 3 和 Step 4：**相同的問題狀態**，
只差一個旗標（`stop_hook_active: true`），結果完全不同。

這演示了為什麼 Stop hook 必須有煞車：
> Claude Code 呼叫 Stop hook → hook 回傳 block → Claude Code 再次嘗試停止 → 再次觸發 Stop hook…
> 沒有煞車 = 無限迴圈。

### 預期效果

- **stdout 完全空白**（煞車直接跳過所有檢查）
- exit code = 0

### 實際驗證結果 ✅

```
exit_code=0
```

即使有 staged 變更，煞車讓 hook 直接通過。測試用的 `quality-gate-test.tmp` 已清理，repo 恢復乾淨狀態。

---

## 本課重點總結

| 觀念 | 說明 |
|------|------|
| Stop hook 時機 | Claude Code **每次停止輸出前**都會觸發 |
| `stop_hook_active` 旗標 | 防止 Stop hook 自己呼叫自己的無限迴圈保護機制 |
| block JSON 格式 | `{"decision": "block", "reason": "..."}` — reason 支援多行，用 awk 自動加編號 |
| 問題清單 | 腳本用 bash array `ISSUES+=()` 累積問題，最後一次性格式化輸出 |
| 乾淨通過 | 沒有問題時**不輸出任何東西**，直接 exit 0 即可 |

## 職場類比

品質守衛 = **公司的 Pre-departure Checklist（出門前清單）**。
每次你（Claude Code）要結束工作離開前，守衛都會問：


- 「有沒有東西沒存？」（未 commit 的變更）
- 「有沒有沒處理完的待辦？」（TODO 標記）

如果有問題 → 擋在門口（block），逼你先處理完再走。
`stop_hook_active` = 守衛本身出門時不需要問自己。
