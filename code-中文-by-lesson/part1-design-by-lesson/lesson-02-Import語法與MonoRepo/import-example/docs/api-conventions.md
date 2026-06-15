# API 設計慣例

## Endpoint 命名

- URL 路徑使用 kebab-case：`/user-profiles`，而非 `/userProfiles`
- 資源集合使用複數名詞：`/users`、`/orders`
- 所有 endpoint 加上版本前綴：`/v1/users`

## 請求/回應格式

所有 endpoint 接受並回傳 JSON。設定 `Content-Type: application/json`。

```json
{
  "data": { ... },
  "meta": {
    "requestId": "abc-123",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

## 錯誤回應

所有錯誤回應一律使用 `ApiError` 型別：

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [...]
  }
}
```

## OpenAPI 文件

每個 endpoint handler 都要加上 OpenAPI 註解。

## 驗證

所有 endpoint 都必須包含輸入驗證。無效請求以 HTTP 400 拒絕。
