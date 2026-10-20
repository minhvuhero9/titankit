#!/usr/bin/env bash
# Prints the UDID of the newest available iPhone simulator, so CI doesn't
# break when the runner image ships different device names.
set -euo pipefail
xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
for runtime in sorted(devices, reverse=True):
    if "iOS" not in runtime:
        continue
    for device in devices[runtime]:
        if device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit(0)
sys.exit("No iPhone simulator found")
'
