#!/bin/bash
set -e

APP_NAME="PortMonitor"
VERSION="${1:-local}"
DIST_DIR="dist"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION-macOS.zip"

SKIP_INSTALL=1 bash build.sh

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

ditto -c -k --keepParent "build/$APP_NAME.app" "$ZIP_PATH"

echo ""
echo "✓ Release listo: $ZIP_PATH"
