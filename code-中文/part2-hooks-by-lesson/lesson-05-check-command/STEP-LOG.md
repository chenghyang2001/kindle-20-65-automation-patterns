# 第 5 課演練記錄：check-command.mjs

> 範例檔：`platform/check-command.mjs`
> demo 腳本：`check-command-demo.mjs`（零修改）+ `echo-command.mjs`（Step 3 自建的回顯測試腳本）
> 事件：`PreToolUse`｜ 難度：⭐⭐
> 主題：和第 4 課做一樣的事（攔危險指令），但改用 Node.js — 跨平台對照組

---

## 核心觀念

- Bash vs Node.js 不是「誰更強」，是**適用場景**
- Node.js 兩大優勢：① 內建 `JSON.parse`（免 jq）② 原生 UTF-8（中文不亂碼）
- 兩個 JS 語法：`?.`（optional chaining，null 不炸）、`??`（nullish coalescing，只有 null/undefined 才用預設值）

---

## Step 1：餵 rm -rf / — 確認 Node.js 版也能擋

**下的命令：**

```bash
echo '{"tool_name": "Bash", "tool_input": {"command": "rm -rf /"}}' | node demo/check-command-demo.mjs
echo $?
```

**目的：** 確認 Node 版攔截行為和 Bash 版一致。

**預期效果：** 阻擋訊息 + exit 2。

**實際驗證結果：** ✅ `已阻擋：'rm -rf' 是被禁止的指令` + exit 2。

- Node 版黑名單寫 `'rm -rf'`（不含斜線，更寬鬆）→ 連 `rm -rf /tmp/foo` 都會擋（比 Bash 版激進）
- Node 版多一個 `tool_name === 'Bash'` 前置過濾（比第 4 課 Bash 版嚴謹）

---

## Step 2：同批變形指令再打一次 — Bash vs Node 穿透率對決

**下的命令：**

```bash
# 把第 4 課 Step 4 的變形指令逐條餵給 Node 版
echo '{"tool_name": "Bash", "tool_input": {"command": "rm -fr /"}}' | node demo/check-command-demo.mjs
# ...（多空格 / 參數對調 / 完整參數名 / 大寫 / find / 變數隱藏）
```

**目的：** 釘死「換語言不會變聰明」— Node 和 Bash 穿透同樣的變形。

**預期效果：** 多空格、參數對調、大寫、換工具 → Bash 和 Node 一樣全部穿透。

**實際驗證結果：** ✅ 結論確認：

- 多空格 / `rm -fr /` / `--recursive --force` / 大寫 / `find / -delete` → **兩版都穿透**（`grep -F` 和 `.includes()` 本質同樣是數字串）
- `TARGET=/; rm -rf $TARGET` → Bash 穿透、Node 擋下，但**差異來自黑名單粗細（Node 寫 `rm -rf` 不含斜線），不是語言**
- 領悟：「用什麼語言寫」和「規則寫得多嚴」是兩個獨立的軸

---

## Step 3：編碼測試 — 中文不再亂碼（Node 主場）

**下的命令：**

```bash
# 自建 echo-command.mjs 回顯指令內容（原腳本命中才印、不回顯）
echo '{"tool_name": "Bash", "tool_input": {"command": "echo 部署完成 && rm 暫存檔.txt"}}' | node demo/echo-command.mjs
```

**目的：** 對比第 2 課 curl 的 cp950 亂碼，證明 Node 原生 UTF-8。

**預期效果：** 中文完整保留。

**實際驗證結果：** ✅ `解析到的指令內容：echo 部署完成 && rm 暫存檔.txt`（完整！）+ 字元數 23（`[...command].length` 按 Unicode 碼位拆字，中文/emoji 都算對）。

- 對比第 2 課：`部署完成` → `a5bf a662...`（cp950 亂碼）
- 原因：Node 內部字串一律 UTF-8，與系統 locale 無關 → Pattern 21 推薦 Node 的第二理由

---

## Step 4：缺欄位防禦 — `?.` 和 `??` 實戰

**下的命令：**

```bash
echo '{}' | node demo/check-command-demo.mjs; echo $?                                      # 全空
echo '{"tool_name": "Bash"}' | node demo/check-command-demo.mjs; echo $?                    # 有 tool_name 沒 tool_input
echo '{"tool_name": "Write", "tool_input": {"file_path": "a.txt"}}' | node ...; echo $?     # 非 Bash 工具
```

**目的：** 看 `tool_input?.command ?? ''` 怎麼優雅不炸。

**預期效果：** 三種殘缺輸入全部 exit 0、零崩潰。

**實際驗證結果：** ✅ 三種全 exit 0：

- 全空 → `tool_name` undefined → `if` 不成立跳過
- 有 tool_name 沒 tool_input → `?.` 看到 undefined 短路 → `?? ''` 補空字串 → 比對沒命中
- Write 工具 → `tool_name === 'Bash'` 不成立
- 若沒 `?.`，`tool_input.command` 會拋 `TypeError` → **hook 崩潰**（PreToolUse hook 崩潰後果嚴重）

---

## 缺欄位防禦三語言版（集滿）

| 課 | 語言 | 寫法 | 挖不到時 |
|----|------|------|---------|
| 第 2 課 | Bash+jq | `// "unknown"` | 預設值 |
| 第 4 課 | Bash+jq | `// empty` | 空字串 |
| 第 5 課 | Node.js | `?.` + `?? ''` | 短路 + 空字串 |

**第 5 課大結論：** 自己玩 mac/Linux + 邏輯簡單 → Bash 夠；要跨平台（Windows）、處理中文、進團隊 repo → Node.js。
**產出物：** `check-command-demo.mjs`、`echo-command.mjs`
