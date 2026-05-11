---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules

- Include input validation in every endpoint
- Use `ApiError` type for all error responses
- Always add OpenAPI comments

---

# Coding Conventions (Global)

## Import Rules
- ES modules only (no `require()`)
- Async operations: use `async/await` (no callbacks)

## Architecture
- All API responses must use types from `src/types/api.ts`
- Database access through `src/repositories/` only

## Naming Conventions
- File names: kebab-case
- Class names: PascalCase
- Function names: camelCase
- Constants: UPPER_SNAKE_CASE
