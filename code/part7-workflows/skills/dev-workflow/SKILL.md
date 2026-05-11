---
name: dev-workflow
description: >
  Launch the 7-stage development workflow.
  Use as the starting point for new features, bug fixes, and refactoring.
disable-model-invocation: true
---

# 7-Stage Development Workflow

**Task**: $ARGUMENTS

## Stage 1: Brainstorm
- Define the task in 1–3 sentences
- State the completion criteria explicitly
- List what is out of scope

## Stage 2: Worktree
- `git worktree add ../work-$ARGUMENTS-$(date +%s) -b feature/$ARGUMENTS`
  (Task name cannot contain spaces. Example: `user-auth` is OK, `user auth` is not)
- All work happens in this worktree

## Stage 3: Plan (run /confidence-check)
- Complete the pre-implementation checklist (see P59)
- Proceed to the next stage only at ≥ 90%

## Stage 4: Sub-agent
- Delegate exploration tasks to the Explore agent

## Stage 5: TDD
- Write tests first, then implement

## Stage 6: Review
- Run `/review` and resolve all issues raised

## Stage 7: Completion
- Commit, remove worktree, run `/session-end`
