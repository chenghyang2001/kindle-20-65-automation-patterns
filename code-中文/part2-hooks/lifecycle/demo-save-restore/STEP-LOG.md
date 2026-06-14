# 第 7 課演練記錄：save-session-state.sh + restore-context.sh

> 範例檔：`lifecycle/save-session-state.sh`（存）+ `lifecycle/restore-context.sh`（讀）
> demo 腳本：`save-session-state-demo.sh` + `restore-context-demo.sh`（修改：狀態檔路徑從 `.claude/` 改到本 demo 目錄的 `session-state.md`）
> 事件：`PreCompact`/`SessionEnd`（存）+ `SessionStart`（讀）｜ 難度：⭐⭐⭐
> 主題：治好 AI 的失憶症 — 兩支腳本聯動的「外接記憶硬碟」

---

## 核心觀念

對話太長 → context 壓縮（compact）→ 關鍵細節遺失（在哪分支、哪個檔案改到一半）。解法：

```
對話快爆 → ① save（PreCompact，把 git 狀態寫進硬碟）
        → 〈compact / 新 session〉
        → ② restore（SessionStart，stdout 被注入 AI context）
        → AI 醒來就知道分支 / 未 commit 檔案
```

**你每天都在用：** session 開頭的「Restored Session Context」就是這套的產物。

---

## Step 1：執行 save — 把當前狀態拍快照存檔

**命令：**

```bash
echo '{"trigger": "manual_test"}' | bash lifecycle/demo-save-restore/save-session-state-demo.sh
cat lifecycle/demo-save-restore/session-state.md
```

**目的：** 看 save 怎麼把會在 compact 遺失的東西用 git 指令打撈出來寫進實體檔。
**預期：** 產出 session-state.md，含分支 / 未 commit 變更 / 最近 commit。
**實際驗證：** ✅ 存檔成功。各區塊對應的 git 指令：

| 區塊 | git 指令 |
|------|---------|
| 觸發來源 | `jq -r '.trigger // "n/a"'`（用第 2 課的預設值防禦）|
| 分支 | `git branch --show-current` |
| 未 commit 變更 | `git diff --name-only` + `--cached`（加 `[staged]` 標記）|
| 最近 commit | `git log --oneline -5` |

⚠️ **自指現象**：save 剛寫的 session-state.md 本身就出現在「未 Commit 的變更」裡（git diff 看到它被修改了）。真實環境中把狀態檔放進 `.gitignore` 可避免此現象。

⚠️ 注意：save 用 `git diff`（**只看已追蹤檔案**），所以 untracked 新檔不會出現（Step 4 改已追蹤檔才看得到效果）。

---

## Step 2：執行 restore — 模擬新 session 讀回記憶

**命令：**

```bash
bash lifecycle/demo-save-restore/restore-context-demo.sh
```

**目的：** 看 restore 的 stdout（真實環境會被注入 AI context）。
**預期：** 輸出「已還原的 Session 上下文」+ 分支 + commit + 上次狀態檔。
**實際驗證：** ✅ 輸出和「每次發訊息上方的 Restored Session Context」幾乎一樣（親眼看到天天在用的機制原始碼）。

**兩條時間線並列展示（本次演練實際觀察到）：**

- **即時 git（此刻）**：最新 commit 是 `73ddae1`（Step 1 commit）
- **上次存檔（07:59）**：最新 commit 還是 `53e1c95`，且 session-state.md 仍「未 commit」
- 一比就知道中間發生什麼：session-state.md 從「未 commit」變成了「已 commit 進 73ddae1」

- **SessionStart 特殊能力**：唯獨它的 stdout 會變成 AI 醒來讀到的第一段記憶
- **兩種資訊合併**：即時查 git（反映「此刻」）+ 讀 session-state.md（反映「上次存檔當下」）→ 一比就知道中間發生什麼
- restore 用 `git status --short`（**含 untracked**），與 save 的 `git diff`（**不含 untracked**）不同 → 同專案兩支腳本看到的「變更」不一樣

---

## Step 3：防禦性寫法檢視 — save 的三道保險（生產級範本）

**命令：**

```bash
cat -n lifecycle/demo-save-restore/save-session-state-demo.sh | head -40
printf '' | bash lifecycle/demo-save-restore/save-session-state-demo.sh
echo $?
```

**目的：** 看這支「12 支裡防禦最完整」的腳本怎麼處理異常。
**預期：** 空輸入照樣 exit 0；寫入失敗 exit 1 報錯。
**實際驗證：** ✅ 三道保險 + 一道隱形保險：

| 保險 | 行 | 作用 |
|------|----|----|
| 一：jq 存在性檢查 | 6-9 | jq 沒裝立刻 exit 1，不留半殘狀態檔 |
| 二：空輸入防禦 | 11-12 | `[ -z "$INPUT" ] && INPUT='{}'`（註解說明為何不用 `${INPUT:-{}}` — 會多吐 `}` 污染 jq，踩坑註解）|
| 三：寫入失敗偵測 | 18-39 | `if ! cat > ...` 失敗 exit 1，避免靜默失敗（回報「已存」但其實沒存）|
| 隱形：git 接 `2>/dev/null` | 23/26/31/34 | 非 git repo 時吞錯誤，不污染狀態檔 |

對應全域規則「原則 1：不可只寫快樂路徑」→ 四種異常（jq 沒裝/stdin 空/寫檔失敗/非 git repo）全處理，是「完全體」範本。

---

## Step 4：完整聯動 — 改個檔，save→restore 走一遍

**命令：**

```bash
echo "進行中的工作" > lifecycle/demo-save-restore/work-in-progress.txt
git add lifecycle/demo-save-restore/work-in-progress.txt
echo '{"trigger": "before_compact"}' | bash lifecycle/demo-save-restore/save-session-state-demo.sh
cat lifecycle/demo-save-restore/session-state.md
# 演練後清理（session-state.md 變動需 commit；work-in-progress.txt reset + rm）
git reset lifecycle/demo-save-restore/work-in-progress.txt && rm lifecycle/demo-save-restore/work-in-progress.txt
```

**目的：** 完整重現失憶→記憶循環，讓「未 commit 變更」區塊真的有東西。
**預期：** 狀態檔抓到 `[staged] work-in-progress.txt`，restore 讀回同樣資訊。
**實際驗證：** ✅ 循環走通：

- save 後狀態檔出現 `[staged] code-中文/.../work-in-progress.txt`
- restore 讀回時「上次有個檔案改到一半（staged）」**跨越存檔/讀回兩個時間點完整保留**
- `[staged]` 前綴由 save 第 27-28 行 `sed 's/^/[staged] /'` 加上 → AI 能分辨「已 git add」vs「還沒」
- 演練後 `git reset` + `rm` 還原，不留痕跡

**比喻：** save = 散會前把白板拍照；restore = 隔天開會投影出來；session-state.md = 那張照片。

**產出物：** `save-session-state-demo.sh`、`restore-context-demo.sh`、`session-state.md`
