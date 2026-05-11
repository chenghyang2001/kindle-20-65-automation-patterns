---
name: deploy
description: >
  Deploy to production. Must be invoked explicitly with the /deploy command.
  Use for: production releases, emergency deployments.
disable-model-invocation: true
---

# Deployment Procedure

Deploy to the production environment.

## 1. Pre-flight Checks

```bash
npm test
npm run build
git status
```

Confirm all tests pass, the build succeeds, and there are no uncommitted changes.

## 2. Deploy

```bash
git push origin main
```

## 3. Verify

- Visit https://app.example.com and confirm the page loads
- Confirm no errors in the error logs

## 4. Slack Notification

Post a deployment complete notification to the `#deployments` channel.
