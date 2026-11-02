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

tuist install
tuist generate --no-open

# Recording reports each image it writes as a failure; that run's result is ignored.
case "${1:-}" in
  record) export TEST_RUNNER_SNAPSHOT_RECORD=1; kit || true; app || true; unset TEST_RUNNER_SNAPSHOT_RECORD ;;
  missing) kit || true; app || true ;;
esac
kit && kit_status=0 || kit_status=$?
app && app_status=0 || app_status=$?
exit $((kit_status + app_status))
