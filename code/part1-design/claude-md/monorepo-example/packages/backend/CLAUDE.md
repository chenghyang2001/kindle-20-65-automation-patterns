# Backend Package

## Tech Stack

Node.js + Express + TypeScript + PostgreSQL

## Database

Always access the database through `src/repositories/`. Direct query execution
outside repositories is not permitted.

## API Development

All endpoints must include:
- Input validation using `src/types/api.ts` types
- `ApiError` for error responses
- OpenAPI JSDoc comments

## Running Locally

```bash
npm run dev       # start dev server (port 3000)
npm run db:seed   # seed database
npm test          # unit + integration tests
```
