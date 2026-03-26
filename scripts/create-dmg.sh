#!/bin/bash
set -euo pipefail

# Usage: ./scripts/create-dmg.sh <app-path> <output-dmg-path>
# Example: ./scripts/create-dmg.sh build/IP-Switch.app build/IP-Switch.dmg

APP_PATH="$1"
DMG_PATH="$2"
APP_NAME="IP Switch"
VOL_NAME="IP Switch"
TMP_DMG="$(mktemp -u /tmp/ip-switch-XXXXXX).dmg"
STAGING_DIR="$(mktemp -d /tmp/ip-switch-staging-XXXXXX)"

echo "Creating DMG from: $APP_PATH"
echo "Output: $DMG_PATH"

# Copy app to staging
cp -R "$APP_PATH" "$STAGING_DIR/"

# Create symlink to /Applications
ln -s /Applications "$STAGING_DIR/Applications"

# Calculate size (app size + 20MB buffer)
SIZE_KB=$(du -sk "$STAGING_DIR" | cut -f1)
SIZE_KB=$((SIZE_KB + 20480))

# Create temporary DMG
hdiutil create -srcfolder "$STAGING_DIR" \
    -volname "$VOL_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size "${SIZE_KB}k" \
    "$TMP_DMG"

# Mount it
MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$TMP_DMG" | \
    grep -E '^\S+\s+Apple_HFS' | awk '{print $3}')

# Set background and icon layout via AppleScript
echo "Setting DMG window layout..."
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 440}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "$APP_NAME.app" of container window to {125, 170}
        set position of item "Applications" of container window to {375, 170}
        close
        open
        update without registering applications
        delay 1
    end tell
end tell
APPLESCRIPT

# Unmount
hdiutil detach "$MOUNT_DIR" -quiet

# Convert to compressed read-only DMG
hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"

# Cleanup
rm -f "$TMP_DMG"
rm -rf "$STAGING_DIR"

echo "DMG created successfully: $DMG_PATH"
