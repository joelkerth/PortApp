#!/bin/bash
set -e

ICON_SRC="/tmp/port_monitor_source.png"
ICONSET_DIR="/tmp/PortMonitor.iconset"
ICNS_OUT="AppIcon.icns"

echo "▸ Generando PNG fuente con Swift..."

# Render SF Symbol sobre fondo degradado (1024×1024) usando AppKit
swift - <<'SWIFT'
import AppKit

let size = NSSize(width: 1024, height: 1024)
let img = NSImage(size: size, flipped: false) { rect in

    // --- Fondo: rect redondeado con degradado azul-teal ---
    let radius: CGFloat = 220
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.addClip()

    let top    = NSColor(red: 0.04, green: 0.52, blue: 1.00, alpha: 1) // #0A84FF
    let bottom = NSColor(red: 0.00, green: 0.78, blue: 0.85, alpha: 1) // #00C7D9
    let grad = NSGradient(starting: top, ending: bottom)!
    grad.draw(in: rect, angle: -60)

    // --- Símbolo: "network" en blanco centrado ---
    let symPt: CGFloat = 500
    let cfg = NSImage.SymbolConfiguration(pointSize: symPt, weight: .medium)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let sym = NSImage(systemSymbolName: "network", accessibilityDescription: nil)?
                     .withSymbolConfiguration(cfg) {
        let symSize = sym.size
        let origin = NSPoint(
            x: (rect.width  - symSize.width)  / 2,
            y: (rect.height - symSize.height) / 2 - 10
        )
        sym.draw(in: NSRect(origin: origin, size: symSize))
    }
    return true
}

guard let tiff   = img.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png    = bitmap.representation(using: .png, properties: [:])
else { print("ERROR: no se pudo generar el PNG"); exit(1) }

try! png.write(to: URL(fileURLWithPath: "/tmp/port_monitor_source.png"))
print("  PNG generado: 1024×1024")
SWIFT

echo "▸ Creando iconset con todos los tamaños..."
rm -rf "$ICONSET_DIR" && mkdir "$ICONSET_DIR"

sips -z 16   16   "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16.png"       -s format png > /dev/null
sips -z 32   32   "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16@2x.png"    -s format png > /dev/null
sips -z 32   32   "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32.png"        -s format png > /dev/null
sips -z 64   64   "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32@2x.png"    -s format png > /dev/null
sips -z 128  128  "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128.png"     -s format png > /dev/null
sips -z 256  256  "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128@2x.png"  -s format png > /dev/null
sips -z 256  256  "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256.png"     -s format png > /dev/null
sips -z 512  512  "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256@2x.png"  -s format png > /dev/null
sips -z 512  512  "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512.png"     -s format png > /dev/null
sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512@2x.png"  -s format png > /dev/null

echo "▸ Convirtiendo a .icns..."
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_OUT"

echo ""
echo "✓ Ícono creado: $ICNS_OUT"
echo ""
echo "  Ahora ejecuta: bash build.sh  para reconstruir la app con el ícono"
