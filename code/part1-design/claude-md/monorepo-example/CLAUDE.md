# Monorepo: my-project

## Shared Rules

- Commit messages: Conventional Commits format
- Branch naming: `feat/`, `fix/`, `chore/` prefixes
- One feature per PR

## Build Commands

- Build all packages: `npm run build --workspaces`
- Build a specific package: `cd packages/[name] && npm run build`

## Restrictions

- Do not create files directly under `packages/` — always create inside a package
- Do not add dependencies directly to the root `package.json`
