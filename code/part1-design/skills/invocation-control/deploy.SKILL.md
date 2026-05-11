---
name: deploy
description: Deploy to production
disable-model-invocation: true
---

# Deployment Procedure

Deploy to the production environment. Follow these steps:

## Pre-flight Checks

```bash
npm test
npm run build
git status
```

## Deploy

```bash
git push origin main
```

## Verify

- Visit the production URL and confirm it works
- Check the error logs
- Post a completion notification to Slack
