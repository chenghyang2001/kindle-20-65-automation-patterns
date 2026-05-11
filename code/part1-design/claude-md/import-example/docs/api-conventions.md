# API Design Conventions

## Endpoint Naming

- Use kebab-case for URL paths: `/user-profiles`, not `/userProfiles`
- Use plural nouns for resource collections: `/users`, `/orders`
- Version prefix for all endpoints: `/v1/users`

## Request/Response Format

All endpoints accept and return JSON. Set `Content-Type: application/json`.

```json
{
  "data": { ... },
  "meta": {
    "requestId": "abc-123",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

## Error Responses

Use `ApiError` type for all error responses:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [...]
  }
}
```

## OpenAPI Documentation

Add OpenAPI comments to every endpoint handler.

## Validation

All endpoints must include input validation. Reject invalid requests with HTTP 400.
