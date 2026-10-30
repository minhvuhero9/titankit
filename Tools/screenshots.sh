#!/usr/bin/env bash
# App Store screenshots of Dolingo, in Vietnamese and English, on the newest iPhone Pro Max
# simulator (the 6.9" size App Store Connect asks for). Writes screenshots/<lang>-<n>-<screen>.png.
# Usage: Tools/screenshots.sh            (run from a Mac with Xcode; CI: the Screenshots workflow)
set -euo pipefail
cd "$(dirname "$0")/.."

UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
for runtime in sorted(devices, reverse=True):
    if "iOS" not in runtime:
        continue
    for device in devices[runtime]:
        if device["name"].startswith("iPhone") and "Pro Max" in device["name"]:
            print(device["udid"])
            sys.exit(0)
sys.exit("No iPhone Pro Max simulator found")
')

tuist install
tuist generate --no-open

# A clean status bar, as on Apple's own screenshots.
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --dataNetwork wifi --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

rm -rf build/Screenshots.xcresult screenshots
mkdir -p screenshots build
xcodebuild test \
  -workspace TitanKit.xcworkspace \
  -scheme Dolingo-Screenshots \
  -destination "id=$UDID" \
  -resultBundlePath build/Screenshots.xcresult \
  CODE_SIGNING_ALLOWED=NO \
  > build/screenshots.log 2>&1 && status=0 || status=$?
grep -E "error:|Executed|\*\* TEST" build/screenshots.log || true

xcrun xcresulttool export attachments --path build/Screenshots.xcresult --output-path build/attachments
python3 - <<'PY'
import json, pathlib, shutil
folder = pathlib.Path("build/attachments")
for test in json.loads((folder / "manifest.json").read_text()):
    for item in test.get("attachments", []):
        name = item.get("suggestedHumanReadableName", item["exportedFileName"])
        # "vi-1-home_0_<uuid>.png" -> "vi-1-home.png"
        stem = name.rsplit(".", 1)[0].split("_", 1)[0]
        shutil.copy(folder / item["exportedFileName"], f"screenshots/{stem}.png")
        print("screenshots/" + stem + ".png")
PY
exit "$status"
