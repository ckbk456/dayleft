#!/bin/bash
# Xcode build phase: records the exact source commit and build time in the built Info.plist,
# so a running copy identifies itself as e.g. 0.2.0+abc1234 (or abc1234.dirty).
set -euo pipefail

plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
commit="unknown"
if git -C "$SRCROOT" rev-parse --verify --quiet HEAD >/dev/null; then
  commit="$(git -C "$SRCROOT" rev-parse --short=7 HEAD)"
  # Uncommitted or untracked (non-ignored) files mean the commit alone does not identify the build.
  if [[ -n "$(git -C "$SRCROOT" status --porcelain)" ]]; then
    commit+=".dirty"
  fi
fi
built_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

for entry in "DayleftCommit:$commit" "DayleftBuiltAt:$built_at"; do
  key="${entry%%:*}"
  /usr/libexec/PlistBuddy -c "Delete :$key" "$plist" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :$key string ${entry#*:}" "$plist"
done
