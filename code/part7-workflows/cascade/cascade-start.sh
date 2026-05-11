#!/usr/bin/env bash
# cascade-start.sh: Launch 3 instances in separate worktrees

BASE_BRANCH=$(git branch --show-current)
TASK=${1:-"feature"}
TS=$(date +%s)

for i in 1 2 3; do
  BRANCH="${TASK}-worker-${i}-${TS}"
  DIR="../work-${TASK}-${i}"
  git worktree add "$DIR" -b "$BRANCH" HEAD
  echo "Worktree $i: $DIR (branch: $BRANCH)"
done

echo "Start: cd ../work-${TASK}-1 && claude"
echo "Start: cd ../work-${TASK}-2 && claude"
echo "Start: cd ../work-${TASK}-3 && claude"
