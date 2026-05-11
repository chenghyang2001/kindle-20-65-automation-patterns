# Go Project

## Setup

```bash
go mod download
go run ./cmd/server
```

## Code Conventions

- Follow `gofmt` formatting (enforced in CI)
- Use `golangci-lint` for linting
- Error handling: always check errors, never use `_` for critical paths

## Testing

```bash
go test ./...                    # run all tests
go test -race ./...              # with race detector
go test -cover ./...             # with coverage
```

## Package Layout

Follow the standard Go project layout:
- `cmd/` — application entry points
- `internal/` — private application code
- `pkg/` — public library code

## Dependencies

Use Go modules. Avoid replacing with local paths in production.
