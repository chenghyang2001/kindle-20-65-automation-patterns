#!/usr/bin/env bash
# Usage: ./install-skill.sh <skill-name> <GitHub repository URL>
# Example: ./install-skill.sh code-review \
#            https://github.com/example/skills

set -euo pipefail
SKILL_NAME=${1:?"skill name is required"}
REPO_URL=${2:?"repository URL is required"}
SCOPE=${3:-"project"}   # project or personal

if [ "$SCOPE" = "personal" ]; then
  DEST="${HOME}/.claude/skills/${SKILL_NAME}"
else
  DEST=".claude/skills/${SKILL_NAME}"
fi

if [ -d "$DEST" ]; then
  echo "ERROR: $DEST already exists" >&2
  exit 1
fi

TMP_CLONE_DIR=$(mktemp -d)
trap "rm -rf $TMP_CLONE_DIR" EXIT

git clone --quiet --depth=1 "$REPO_URL" "$TMP_CLONE_DIR/repo"

if [ ! -d "$TMP_CLONE_DIR/repo/skills/$SKILL_NAME" ]; then
  echo "ERROR: Skill '$SKILL_NAME' not found" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
cp -r "$TMP_CLONE_DIR/repo/skills/$SKILL_NAME" "$DEST"
echo "Install complete: $DEST"
