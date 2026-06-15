# Go 專案

## 設定

```bash
go mod download
go run ./cmd/server
```

## 程式碼慣例

- 遵循 `gofmt` 格式化（CI 強制執行）
- 使用 `golangci-lint` 做 lint
- 錯誤處理：一律檢查 error，關鍵路徑絕不用 `_` 忽略

## 測試

```bash
go test ./...                    # 執行所有測試
go test -race ./...              # 加上 race detector
go test -cover ./...             # 含覆蓋率
```

## 套件佈局

遵循標準 Go 專案佈局：

- `cmd/` — 應用程式進入點
- `internal/` — 私有應用程式碼
- `pkg/` — 公開函式庫程式碼

## 依賴管理

使用 Go modules。生產環境避免用 replace 指向本機路徑。
