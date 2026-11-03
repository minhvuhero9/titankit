#!/usr/bin/env bash
# Runs the snapshot tests: the kit's (Packages/TitanKit/Tests/TitanSnapshotTests) and
# Dolingo's (Apps/Dolingo/SnapshotTests).
# Usage: Tools/snapshots.sh          compare with the images in __Snapshots__
#        Tools/snapshots.sh missing  record only images that don't exist yet, then compare
#        Tools/snapshots.sh record   rewrite every image, then compare again
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$(pwd)
UDID=$(Tools/ci-simulator.sh)

kit() {
  (cd Packages/TitanKit && xcodebuild test \
    -scheme TitanKit-Package \
    -destination "id=$UDID" \
    -only-testing:TitanSnapshotTests \
    -skipPackagePluginValidation) > "$ROOT/build-snapshots-kit.log" 2>&1 && status=0 || status=$?
  grep -E "error:|Executed|\*\* (TEST|BUILD)" "$ROOT/build-snapshots-kit.log" || true
  return "$status"
}

app() {
  xcodebuild test \
    -workspace TitanKit.xcworkspace \
    -scheme Dolingo-Dev \
    -destination "id=$UDID" \
    -only-testing:DolingoSnapshotTests \
    CODE_SIGNING_ALLOWED=NO \
    > "$ROOT/build-snapshots-app.log" 2>&1 && status=0 || status=$?
  grep -E "error:|Executed|\*\* (TEST|BUILD)" "$ROOT/build-snapshots-app.log" || true
  return "$status"
}

# Recording reports each image it writes as a failure; that run's result is ignored.
record() {
  case "${1:-}" in
    record) export TEST_RUNNER_SNAPSHOT_RECORD=1; "$2" || true; unset TEST_RUNNER_SNAPSHOT_RECORD ;;
    missing) "$2" || true ;;
  esac
}

# The kit first: once Tuist has generated the workspace, Packages/TitanKit holds a generated
# .xcodeproj and xcodebuild no longer sees the package's TitanKit-Package scheme.
record "${1:-}" kit
kit && kit_status=0 || kit_status=$?

tuist install
tuist generate --no-open
record "${1:-}" app
app && app_status=0 || app_status=$?
exit $((kit_status + app_status))
