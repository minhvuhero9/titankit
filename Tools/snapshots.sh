#!/usr/bin/env bash
# Runs the kit's snapshot tests (Packages/TitanKit/Tests/TitanSnapshotTests).
# Usage: Tools/snapshots.sh          compare with the images in __Snapshots__
#        Tools/snapshots.sh missing  record only images that don't exist yet, then compare
#        Tools/snapshots.sh record   rewrite every image, then compare again
set -euo pipefail
cd "$(dirname "$0")/../Packages/TitanKit"
UDID=$("../../Tools/ci-simulator.sh")

run() {
  xcodebuild test \
    -scheme TitanKit-Package \
    -destination "id=$UDID" \
    -only-testing:TitanSnapshotTests \
    -skipPackagePluginValidation \
    > ../../build-snapshots.log 2>&1 && status=0 || status=$?
  grep -E "error:|Executed|\*\* (TEST|BUILD)" ../../build-snapshots.log || true
  return "$status"
}

# Recording reports each image it writes as a failure; that run's result is ignored.
case "${1:-}" in
  record) TEST_RUNNER_SNAPSHOT_RECORD=1 run || true ;;
  missing) run || true ;;
esac
run
