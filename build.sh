#!/bin/bash
set -e

APP_NAME="PortMonitor"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

echo "▸ Limpiando build anterior..."
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "▸ Compilando Swift..."
swiftc Sources/*.swift \
    -o "$MACOS_DIR/$APP_NAME" \
    -framework AppKit \
    -framework Foundation \
    -target arm64-apple-macos12.0 \
    2>&1 | sed 's/^/  /'

# Si falla arm64, reintenta sin -target (detecta la arquitectura automáticamente)
if [ ! -f "$MACOS_DIR/$APP_NAME" ]; then
    echo "  Reintentando sin flag -target..."
    swiftc Sources/*.swift \
        -o "$MACOS_DIR/$APP_NAME" \
        -framework AppKit \
        -framework Foundation
fi

echo "▸ Copiando Info.plist..."
cp Info.plist "$APP_BUNDLE/Contents/"

echo "▸ Copiando ícono..."
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$RESOURCES_DIR/"
else
    echo "  (sin AppIcon.icns — ejecuta: bash make_icon.sh)"
fi

echo "▸ Instalando en /Applications..."
pkill "$APP_NAME" 2>/dev/null; sleep 0.2
cp -r "$APP_BUNDLE" /Applications/
# Eliminar el .app del directorio de build para que Launchpad no lo indexe
rm -rf "$APP_BUNDLE"

echo ""
echo "✓ Instalado en /Applications/$APP_NAME.app"
echo ""
echo "  Ejecutar: open /Applications/$APP_NAME.app"
