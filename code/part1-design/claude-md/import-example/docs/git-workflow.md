# Git Workflow

## Branch Naming

- `feat/` — new features
- `fix/` — bug fixes
- `chore/` — maintenance, dependency updates

## Commit Messages

Follow Conventional Commits format:

```
feat(auth): add JWT refresh token support
fix(api): handle null response in user endpoint
chore(deps): update express to 4.18.2
```

## Pull Requests

- One PR per feature or fix
- Link to the related issue
- Require at least one reviewer approval before merge

## Merge Strategy

Use squash merge for feature branches. Preserve commit history on main.
