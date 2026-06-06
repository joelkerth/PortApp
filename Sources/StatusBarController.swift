import AppKit

class StatusBarController {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var refreshTimer: Timer?
    private var menuDelegate: MenuDelegate?          // strong ref — NSMenu.delegate is weak
    private let settings = SettingsWindowController()

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        let delegate = MenuDelegate { [weak self] in self?.rebuildMenu() }
        menuDelegate = delegate
        menu.delegate = delegate
        menu.minimumWidth = PortMenuItemView.menuWidth
        statusItem.menu = menu

        // Background badge refresh every 5 s
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refreshBadge()
        }
        refreshBadge()
    }

    // MARK: – Badge

    private func refreshBadge() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let hasPorts = !PortScanner.scan().isEmpty
            DispatchQueue.main.async {
                self?.statusItem.button?.image = Self.makeStatusIcon(hasPorts: hasPorts)
            }
        }
    }

    // Composite icon: network symbol + optional green dot in the top-right corner.
    // Uses a lazy NSImage so the drawing handler runs inside AppKit's appearance
    // context each time — this keeps the SF symbol correct in dark/light mode.
    private static func makeStatusIcon(hasPorts: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: false) { rect in
            let cfg = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            if let sym = NSImage(systemSymbolName: "network", accessibilityDescription: nil)?
                .withSymbolConfiguration(cfg) {
                sym.draw(in: rect)
            }
            if hasPorts {
                NSColor.systemGreen.setFill()
                let d: CGFloat = 5
                NSBezierPath(ovalIn: NSRect(x: rect.maxX - d, y: rect.maxY - d, width: d, height: d)).fill()
            }
            return true
        }
        img.isTemplate = false
        return img
    }

    // MARK: – Menu

    private func rebuildMenu() {
        menu.removeAllItems()

        let ports = PortScanner.scan()

        // Update badge inline so it's instant when the menu opens
        statusItem.button?.image = Self.makeStatusIcon(hasPorts: !ports.isEmpty)

        if ports.isEmpty {
            let empty = NSMenuItem(title: "No hay puertos activos", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            let header = NSMenuItem(title: "Puertos activos  (\(ports.count))", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
            menu.addItem(.separator())

            for info in ports {
                let item = NSMenuItem()
                let row = PortMenuItemView(info: info)
                row.onOpen = { [weak self] in self?.openPort(info.port) }
                row.onKill = { [weak self] in self?.killPort(info) }
                item.view = row
                menu.addItem(item)
            }
        }

        // Footer row: settings | refresh | quit
        let footerItem = NSMenuItem()
        let footer = MenuFooterView()
        footer.onSettings = { [weak self] in self?.settings.show() }
        footer.onRefresh  = { [weak self] in self?.rebuildMenu() }
        footer.onQuit     = { NSApp.terminate(nil) }
        footerItem.view = footer
        menu.addItem(footerItem)
    }

    private func openPort(_ port: Int) {
        guard let url = URL(string: "http://localhost:\(port)") else { return }
        NSWorkspace.shared.open(url)
    }

    private func killPort(_ info: PortInfo) {
        let ok = PortScanner.kill(pid: info.pid)
        if !ok {
            let alert = NSAlert()
            alert.messageText = "No se pudo terminar el proceso"
            alert.informativeText = "PID \(info.pid) (\(info.processName)) requiere permisos de superusuario.\nTermínalo manualmente en Terminal con: sudo kill -9 \(info.pid)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.rebuildMenu()
        }
    }
}

// MARK: – MenuDelegate

private class MenuDelegate: NSObject, NSMenuDelegate {
    private let onWillOpen: () -> Void
    init(_ block: @escaping () -> Void) { self.onWillOpen = block }
    func menuWillOpen(_ menu: NSMenu) { onWillOpen() }
}
