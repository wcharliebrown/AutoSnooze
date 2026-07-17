#!/bin/zsh
# Rebuilds, re-signs, and reinstalls AutoSnooze on the iPhone. Run manually
# to renew the yearly paid-team provisioning profile or push code changes.
# (Formerly run daily by a launchd agent when the app used free 7-day signing.)
set -u

PROJ_DIR="/Volumes/StudioMacCharlie/DocumentsClearSkyCB/iOS/AutoSnooze"
DEVICE_UDID="812F4DC2-CF0D-5F69-9E52-6A868250C770"   # iPhonecb (iPhone 12)
STATE_DIR="$HOME/Library/Application Support/AutoSnoozeRefresh"
LOG="$STATE_DIR/refresh.log"

mkdir -p "$STATE_DIR"
exec >> "$LOG" 2>&1
echo "=== refresh attempt $(date) ==="

cd "$PROJ_DIR" || exit 1

if xcodebuild -project AutoSnooze.xcodeproj -scheme AutoSnooze \
      -destination 'generic/platform=iOS' \
      -derivedDataPath "$STATE_DIR/DerivedData" \
      -allowProvisioningUpdates build \
   && xcrun devicectl device install app --device "$DEVICE_UDID" \
      "$STATE_DIR/DerivedData/Build/Products/Debug-iphoneos/AutoSnooze.app"; then
    date +%s > "$STATE_DIR/last-success"
    echo "=== OK $(date) ==="
else
    echo "=== FAILED $(date) ==="
    last=$(cat "$STATE_DIR/last-success" 2>/dev/null || echo 0)
    age_days=$(( ($(date +%s) - last) / 86400 ))
    # Only nag when the signature is actually at risk (5+ days since success)
    if (( age_days >= 5 )); then
        osascript -e 'display notification "Signature expires soon — connect the iPhone to this Mac, or re-enter your Apple ID in Xcode Settings > Accounts." with title "AutoSnooze refresh failing"'
    fi
fi

tail -n 500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
