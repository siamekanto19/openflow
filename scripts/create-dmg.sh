#!/bin/bash
set -e

APP_NAME="OpenFlow"
DMG_NAME="${APP_NAME}-Installer"
BUNDLE_DIR="build/${APP_NAME}.app"
DMG_DIR="build/dmg"
DMG_PATH="build/${DMG_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"

# Check that the .app bundle exists
if [ ! -d "$BUNDLE_DIR" ]; then
    echo "❌ ${BUNDLE_DIR} not found. Run 'make bundle' first."
    exit 1
fi

echo "📦 Creating DMG installer..."

# Clean up any previous DMG artifacts
rm -rf "$DMG_DIR"
rm -f "$DMG_PATH"
rm -f "build/${DMG_NAME}-temp.dmg"

# Create staging directory
mkdir -p "$DMG_DIR"

# Copy the .app bundle
cp -r "$BUNDLE_DIR" "$DMG_DIR/"

# Create symlink to /Applications
ln -s /Applications "$DMG_DIR/Applications"

# Create a temp DMG (read-write) with enough space
hdiutil create \
    -srcFolder "$DMG_DIR" \
    -volname "$VOLUME_NAME" \
    -fs HFS+ \
    -format UDRW \
    -size 200m \
    "build/${DMG_NAME}-temp.dmg"

# Mount the temp DMG
MOUNT_DIR=$(hdiutil attach "build/${DMG_NAME}-temp.dmg" | grep "$VOLUME_NAME" | awk '{print $3}')
echo "Mounted at: $MOUNT_DIR"

# Use AppleScript to configure the DMG window appearance
osascript <<EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 120, 760, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100
        set position of item "${APP_NAME}.app" of container window to {140, 200}
        set position of item "Applications" of container window to {420, 200}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Unmount
sync
hdiutil detach "$MOUNT_DIR"

# Convert to compressed read-only DMG
hdiutil convert \
    "build/${DMG_NAME}-temp.dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH"

# Clean up
rm -f "build/${DMG_NAME}-temp.dmg"
rm -rf "$DMG_DIR"

# Get file size
DMG_SIZE=$(du -h "$DMG_PATH" | awk '{print $1}')

echo ""
echo "✅ DMG installer created: $DMG_PATH ($DMG_SIZE)"
echo "   Double-click the DMG, then drag ${APP_NAME} to Applications."
