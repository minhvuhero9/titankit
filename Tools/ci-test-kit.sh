#!/usr/bin/env bash
# Builds and tests every TitanKit module on an iOS simulator.
set -euo pipefail
cd "$(dirname "$0")/../Packages/TitanKit"
UDID=$("../../Tools/ci-simulator.sh")
xcodebuild test \
  -scheme TitanKit-Package \
  -destination "id=$UDID" \
  -skipPackagePluginValidation \
  > ../../build-kit.log 2>&1 && status=0 || status=$?
grep -E "error:|Executed|\*\* (TEST|BUILD)" ../../build-kit.log || true
exit "$status"
