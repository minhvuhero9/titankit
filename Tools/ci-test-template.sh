#!/usr/bin/env bash
# Makes a throwaway app from Tuist/Templates/NewApp, then builds and tests it, so the template
# keeps working as the kit changes. Run after Tools/ci-test-app.sh (reuses its build).
set -euo pipefail
cd "$(dirname "$0")/.."
NAME=TemplateCheck
trap 'rm -rf "Apps/$NAME"' EXIT

tuist scaffold NewApp --name "$NAME" --company titankit
tuist install
tuist generate --no-open
UDID=$(Tools/ci-simulator.sh)
xcodebuild test \
  -workspace TitanKit.xcworkspace \
  -scheme "$NAME-Dev" \
  -destination "id=$UDID" \
  CODE_SIGNING_ALLOWED=NO \
  > build-template.log 2>&1 && status=0 || status=$?
grep -E "error:|Executed|\*\* (TEST|BUILD)" build-template.log || true
exit "$status"
