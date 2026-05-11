# Next.js Project

## Setup

```bash
npm install
npm run dev    # start dev server (port 3000)
```

## Code Conventions

- Use TypeScript strict mode
- Prefer Server Components; use Client Components only when necessary
- Co-locate page-specific components with the page file

## Testing

```bash
npm test             # unit tests (Jest + Testing Library)
npm run test:e2e     # end-to-end tests (Playwright)
```

## Data Fetching

- Use Server Components for data fetching where possible
- Use React Query for client-side data that requires caching
- Never fetch data in Client Components that could be fetched on the server

## Environment Variables

- Server-only secrets: no `NEXT_PUBLIC_` prefix
- Client-safe config: `NEXT_PUBLIC_` prefix required
