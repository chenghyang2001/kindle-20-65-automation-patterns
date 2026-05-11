# Testing Guidelines

## Test Structure

Place all tests under `tests/`, mirroring the source directory structure.

## Coverage Requirements

- Minimum 80% line coverage for all modules
- 100% coverage required for critical paths (auth, payment)

## Test Types

- **Unit tests**: Pure functions, isolated logic
- **Integration tests**: API endpoints, database interactions
- **E2E tests**: Full user workflows (Playwright)

## Running Tests

```bash
npm test              # unit + integration
npm run test:e2e      # end-to-end tests
npm run test:coverage # with coverage report
```

## Naming Convention

Test files: `*.test.ts` for unit, `*.spec.ts` for integration.

## Mocking

Use `vi.mock()` for external dependencies. Never mock internal modules.
