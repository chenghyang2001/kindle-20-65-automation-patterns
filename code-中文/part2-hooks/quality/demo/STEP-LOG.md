# 第 3 課演練記錄：auto-format.sh

> 範例檔：`quality/auto-format.sh`
> demo 腳本：`auto-format-demo.sh`（零修改 — 效果直接作用在目標檔案上，本來就看得見）
> 事件：`PostToolUse`（matcher = `Edit|Write`，即「AI 改完/寫完檔案之後」）｜ 難度：⭐⭐
> 主題：AI 寫完檔案自動格式化 + 白名單思維

---

## 核心觀念

- 掛在 PostToolUse，AI 每次寫完檔案就自動跑格式化工具（按副檔名分流）
- **白名單思維**：明確列出我會處理的類型（js/go/py/md），其他一律安全放行
- demo 素材：`messy.json`（擠一行的醜 JSON）、`messy.js`（亂排版 JS）、`note.txt`（局外人）

---

## Step 1：格式化醜 JSON — 親眼看前後對比

**下的命令：**


```bash
cat demo/messy.json   # 看醜樣
echo '{"tool_input": {"file_path": "demo/messy.json"}}' | bash demo/auto-format-demo.sh
cat demo/messy.json   # 看美化後
```

**目的：** 看 PostToolUse hook 怎麼就地改寫檔案的排版。

**預期效果：** 124 字元擠一行 → 縮排 2 格、冒號後加空格、巢狀展開。

**實際驗證結果：** ✅ 就地美化成功。腳本三段式走完：jq 挖路徑 → `[ -z ]` 檢查 → `${FILE_PATH##*.}` 取副檔名 → case 命中 `json` → `npx prettier --write`。prettier 自印 `demo/messy.json 27ms`（**27ms** = 可放心掛 PostToolUse 每次寫檔都跑）。

---

## Step 2：格式化醜 JS — 看 prettier 整理程式碼


**下的命令：**

```bash
cat demo/messy.js
echo '{"tool_input": {"file_path": "demo/messy.js"}}' | bash demo/auto-format-demo.sh
cat demo/messy.js
```

**目的：** 看 prettier 對「程式碼」動的手術比 JSON 多。

**預期效果：** 大括號換行、運算子補空格、補分號、刪多餘空格、一行一敘述、箭頭函式參數補括號。

**實際驗證結果：** ✅ 全部到位，**功能完全沒變**（只改儀容不改邏輯 → 這是格式化工具與第 10 課 AI 裁判的分工）。中文字串 `"哈囉, "` 安然無恙（prettier 內部 UTF-8，與第 2 課 curl 的 cp950 坑不同路徑）。

---

## Step 3：餵局外人 note.txt — 驗證「不關我的事就放行」


**下的命令：**

```bash
cat demo/note.txt && sha256sum demo/note.txt
echo '{"tool_input": {"file_path": "demo/note.txt"}}' | bash demo/auto-format-demo.sh
cat demo/note.txt && sha256sum demo/note.txt
```

**目的：** 驗證 txt（不在 case 清單）不被動到，用 SHA256 指紋當鐵證。

**預期效果：** 前後 SHA256 一致 + exit 0。

**實際驗證結果：** ✅ 前後指紋都是 `1e70b912fe71...aedd9bf`，**連一個位元組都沒動**。case 四個分支全沒命中 → 默默 exit 0。白名單思維：認識的才處理，不認識的安全放行（不報錯、不雞婆亂改）。

---


## Step 4：餵「沒有 file_path」的 JSON — 驗證提前離場

**下的命令：**

```bash
echo '{"tool_name": "Bash", "tool_input": {"command": "ls -la"}}' | bash demo/auto-format-demo.sh
echo $?
```

**目的：** 模擬 Bash 工具事件（無 file_path），驗證 guard clause 提前離場。

**預期效果：** `[ -z "$FILE_PATH" ]` 命中 → 第二行就 exit 0，連 case 都不跑。

**實際驗證結果：** ✅ exit 0、無輸出。用 `// empty`（挖不到回空字串）+ `[ -z ]`（空字串檢查）組合，對應全域規則「巢狀太深 → 提前 return」。

---

## jq 缺欄位三姿勢（三課集齊）

| 寫法 | 挖不到時得到 | 適用 | 課 |
|------|------------|------|----|
| `jq -r '.x'` | 字串 `"null"` | 純記錄無所謂 | 第 1 課 |
| `jq -r '.x // "unknown"'` | 預設值 | 下游一定要有值 | 第 2 課 |
| `jq -r '.x // empty'` | 空字串 | 下游要判斷要不要繼續 | 第 3 課 |

**產出物：** `auto-format-demo.sh`、格式化後的 `messy.json` / `messy.js`、毫髮無傷的 `note.txt`
