#!/bin/bash
set -euo pipefail

# Usage: ./scripts/create-dmg.sh <app-path> <output-dmg-path>
# Example: ./scripts/create-dmg.sh build/IP-Switch.app build/IP-Switch.dmg

APP_PATH="$1"
DMG_PATH="$2"
VOL_NAME="IP Switch"
STAGING_DIR="$(mktemp -d /tmp/ip-switch-staging-XXXXXX)"

echo "Creating DMG from: $APP_PATH"
echo "Output: $DMG_PATH"

# Copy app to staging
cp -R "$APP_PATH" "$STAGING_DIR/"

# Create symlink to /Applications
ln -s /Applications "$STAGING_DIR/Applications"

# Create compressed read-only DMG directly from staging folder
hdiutil create \
    -srcfolder "$STAGING_DIR" \
    -volname "$VOL_NAME" \
    -fs HFS+ \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_PATH"

# Cleanup
rm -rf "$STAGING_DIR"

echo "DMG created successfully: $DMG_PATH"
