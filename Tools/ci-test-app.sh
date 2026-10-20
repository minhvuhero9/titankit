#!/usr/bin/env bash
# Generates the workspace with Tuist, then builds and tests one app in Dev.
# Usage: Tools/ci-test-app.sh Dolingo
set -euo pipefail
APP="${1:?app name required}"
cd "$(dirname "$0")/.."
tuist install
tuist generate --no-open
UDID=$(Tools/ci-simulator.sh)
xcodebuild test \
  -workspace TitanKit.xcworkspace \
  -scheme "$APP-Dev" \
  -destination "id=$UDID" \
  CODE_SIGNING_ALLOWED=NO \
  > "build-$APP.log" 2>&1 && status=0 || status=$?
grep -E "error:|Executed|\*\* (TEST|BUILD)" "build-$APP.log" || true
exit "$status"
