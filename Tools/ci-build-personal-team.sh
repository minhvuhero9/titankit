#!/usr/bin/env bash
# Builds Dolingo-Dev the way a free Apple ID (Personal Team) generates it, and checks the app
# target links no StoreKit.framework: Xcode turns that link into the In-App Purchase capability,
# which a Personal Team can't sign. Run after Tools/ci-test-app.sh Dolingo (reuses its build).
set -euo pipefail
cd "$(dirname "$0")/.."
PROJECT=Apps/Dolingo/Dolingo.xcodeproj/project.pbxproj

echo "StoreKit.framework references, default generate: $(grep -c 'StoreKit.framework' "$PROJECT" || true)"
TUIST_PERSONAL_TEAM=1 tuist generate --no-open
links=$(grep -c 'StoreKit.framework' "$PROJECT" || true)
echo "StoreKit.framework references, Personal Team generate: $links"
if [ "$links" != "0" ]; then
  echo "error: the Personal Team app target still links StoreKit.framework" >&2
  exit 1
fi

UDID=$(Tools/ci-simulator.sh)
xcodebuild build \
  -workspace TitanKit.xcworkspace \
  -scheme Dolingo-Dev \
  -destination "id=$UDID" \
  CODE_SIGNING_ALLOWED=NO \
  > build-Dolingo-personal.log 2>&1 && status=0 || status=$?
grep -E "error:|\*\* BUILD" build-Dolingo-personal.log || true
exit "$status"
