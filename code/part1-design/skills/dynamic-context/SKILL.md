---
name: pr-summary
description: Summarize the content of a Pull Request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull Request Information
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`
- PR overview: !`gh pr view`

## Task

Summarize the Pull Request from the following angles:

1. Purpose and background of the changes
2. Main changes (file by file)
3. Points to watch during review
4. Potential risks

---

# branch-analysis Skill Sample

Another example of dynamic context injection (for branch analysis):

```yaml
name: branch-analysis
description: Analyze changes in the current branch
```

## Current Branch Info (injected at runtime)

- Branch: !`git branch --show-current`
- Diff from base branch: !`git diff origin/main --stat`
- Commits: !`git log origin/main..HEAD --oneline`
