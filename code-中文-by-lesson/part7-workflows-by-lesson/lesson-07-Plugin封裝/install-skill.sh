#!/usr/bin/env bash
# 使用方式：./install-skill.sh <skill 名稱> <GitHub repository URL>
# 範例：   ./install-skill.sh code-review \
#            https://github.com/example/skills

set -euo pipefail
SKILL_NAME=${1:?"需要 skill 名稱"}
REPO_URL=${2:?"需要 repository URL"}
SCOPE=${3:-"project"}   # project（專案）或 personal（個人）

if [ "$SCOPE" = "personal" ]; then
  DEST="${HOME}/.claude/skills/${SKILL_NAME}"
else
  DEST=".claude/skills/${SKILL_NAME}"
fi

if [ -d "$DEST" ]; then
  echo "錯誤：$DEST 已經存在" >&2
  exit 1
fi

TMP_CLONE_DIR=$(mktemp -d)
trap "rm -rf $TMP_CLONE_DIR" EXIT

git clone --quiet --depth=1 "$REPO_URL" "$TMP_CLONE_DIR/repo"

if [ ! -d "$TMP_CLONE_DIR/repo/skills/$SKILL_NAME" ]; then
  echo "錯誤：找不到 Skill「$SKILL_NAME」" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
cp -r "$TMP_CLONE_DIR/repo/skills/$SKILL_NAME" "$DEST"
echo "安裝完成：$DEST"
