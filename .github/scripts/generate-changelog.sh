#!/bin/bash
set -euo pipefail

PREVIOUS_TAG="${1:?Usage: generate-changelog.sh PREVIOUS_TAG NEW_TAG}"
NEW_TAG="${2:?Usage: generate-changelog.sh PREVIOUS_TAG NEW_TAG}"
NEW_VERSION="${NEW_TAG#v}"
REPO_URL="https://github.com/fleetyards/fleetyards"
DATE=$(date +%Y-%m-%d)

FEATURES=""
FIXES=""
REFACTORS=""

while IFS= read -r line; do
  [ -z "$line" ] && continue

  HASH="${line%% *}"
  MSG="${line#* }"
  SHORT_HASH="${HASH:0:7}"
  LINK="[${SHORT_HASH}](${REPO_URL}/commit/${HASH})"

  case "$MSG" in
    feat\(*\):*)
      SCOPE=$(echo "$MSG" | sed 's/feat(\([^)]*\)):.*/\1/')
      DESC=$(echo "$MSG" | sed 's/feat([^)]*): *//')
      FEATURES="${FEATURES}* **${SCOPE}:** ${DESC} (${LINK})"$'\n'
      ;;
    feat:*|feat\ *)
      DESC=$(echo "$MSG" | sed 's/feat[: ] *//')
      FEATURES="${FEATURES}* ${DESC} (${LINK})"$'\n'
      ;;
    fix\(*\):*)
      SCOPE=$(echo "$MSG" | sed 's/fix(\([^)]*\)):.*/\1/')
      DESC=$(echo "$MSG" | sed 's/fix([^)]*): *//')
      FIXES="${FIXES}* **${SCOPE}:** ${DESC} (${LINK})"$'\n'
      ;;
    fix:*|fix\ *)
      DESC=$(echo "$MSG" | sed 's/fix[: ] *//')
      FIXES="${FIXES}* ${DESC} (${LINK})"$'\n'
      ;;
    refactor\(*\):*)
      SCOPE=$(echo "$MSG" | sed 's/refactor(\([^)]*\)):.*/\1/')
      DESC=$(echo "$MSG" | sed 's/refactor([^)]*): *//')
      REFACTORS="${REFACTORS}* **${SCOPE}:** ${DESC} (${LINK})"$'\n'
      ;;
    refactor:*|refactor\ *)
      DESC=$(echo "$MSG" | sed 's/refactor[: ] *//')
      REFACTORS="${REFACTORS}* ${DESC} (${LINK})"$'\n'
      ;;
  esac
done < <(git log "${PREVIOUS_TAG}..HEAD" --format="%H %s" --no-merges)

# Build header
echo "### [${NEW_VERSION}](${REPO_URL}/compare/${PREVIOUS_TAG}...${NEW_TAG}) (${DATE})"
echo ""

if [ -n "$FEATURES" ]; then
  echo ""
  echo "### Features"
  echo ""
  printf '%s' "$FEATURES"
fi

if [ -n "$FIXES" ]; then
  echo ""
  echo "### Bug Fixes"
  echo ""
  printf '%s' "$FIXES"
fi

if [ -n "$REFACTORS" ]; then
  echo ""
  echo "### Refactorings"
  echo ""
  printf '%s' "$REFACTORS"
fi

echo ""
echo "### Image"
echo "ghcr.io/fleetyards/app:${NEW_TAG}"
