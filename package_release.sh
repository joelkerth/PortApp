#!/bin/bash
set -e

APP_NAME="PortMonitor"
VERSION="${1:-local}"
DIST_DIR="dist"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION-macOS.zip"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION-macOS.dmg"
DMG_ROOT="$DIST_DIR/dmg-root"

SKIP_INSTALL=1 bash build.sh

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

ditto -c -k --keepParent "build/$APP_NAME.app" "$ZIP_PATH"

mkdir -p "$DMG_ROOT"
cp -R "build/$APP_NAME.app" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH" > /dev/null

rm -rf "$DMG_ROOT"

echo ""
echo "✓ ZIP listo: $ZIP_PATH"
echo "✓ DMG listo: $DMG_PATH"
