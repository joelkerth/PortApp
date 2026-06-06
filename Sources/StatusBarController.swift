import AppKit

class StatusBarController {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var refreshTimer: Timer?
    private var menuDelegate: MenuDelegate?          // strong ref — NSMenu.delegate is weak
    private let settings = SettingsWindowController()
    private var searchText = ""
    private var filter: PortFilter = .active
    private var currentPorts: [PortInfo] = []
    private var rowItems: [(item: NSMenuItem, info: PortInfo)] = []
    private weak var countItem: NSMenuItem?
    private weak var emptyItem: NSMenuItem?
    private weak var rowSeparatorItem: NSMenuItem?

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
            let hasPorts = !PortScanner.scan().filter { !PortPreferences.isIgnored($0) }.isEmpty
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
        rowItems.removeAll()

        let ports = PortScanner.scan()
        currentPorts = ports

        // Update badge inline so it's instant when the menu opens
        statusItem.button?.image = Self.makeStatusIcon(hasPorts: ports.contains { !PortPreferences.isIgnored($0) })

        let headerItem = NSMenuItem()
        let headerView = PortFilterHeaderView(searchText: searchText, filter: filter)
        headerView.onSearch = { [weak self] text in
            self?.searchText = text
            self?.applyCurrentFilter()
        }
        headerView.onFilter = { [weak self] filter in
            self?.filter = filter
            self?.applyCurrentFilter()
        }
        headerItem.view = headerView
        menu.addItem(headerItem)

        let empty = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        empty.isEnabled = false
        emptyItem = empty
        menu.addItem(empty)

        let count = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        count.isEnabled = false
        countItem = count
        menu.addItem(count)

        let separator = NSMenuItem.separator()
        rowSeparatorItem = separator
        menu.addItem(separator)

        for info in ports {
            let item = NSMenuItem()
            let row = PortMenuItemView(info: info)
            row.onOpen = { [weak self] in self?.openPort(info.port) }
            row.onKill = { [weak self] in self?.killPort(info) }
            row.onFavorite = { [weak self] in
                PortPreferences.toggleFavorite(info)
                self?.rebuildMenu()
            }
            row.onIgnore = { [weak self] in
                PortPreferences.toggleIgnored(info)
                self?.rebuildMenu()
            }
            item.view = row
            rowItems.append((item, info))
            menu.addItem(item)
        }

        applyCurrentFilter()

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

    private func filtered(_ ports: [PortInfo]) -> [PortInfo] {
        let base: [PortInfo]
        switch filter {
        case .active:
            base = ports.filter { !PortPreferences.isIgnored($0) }
        case .favorites:
            base = ports.filter { PortPreferences.isFavorite($0) && !PortPreferences.isIgnored($0) }
        case .ignored:
            base = ports.filter { PortPreferences.isIgnored($0) }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return base }
        return base.filter { $0.searchableText.contains(query) }
    }

    private func applyCurrentFilter() {
        let visibleIDs = Set(filtered(currentPorts).map(\.id))
        let visibleCount = rowItems.reduce(0) { count, row in
            let isVisible = visibleIDs.contains(row.info.id)
            row.item.isHidden = !isVisible
            return count + (isVisible ? 1 : 0)
        }

        let hasRows = visibleCount > 0
        emptyItem?.isHidden = hasRows
        emptyItem?.title = currentPorts.isEmpty ? "No hay puertos activos" : "No hay resultados para este filtro"
        countItem?.isHidden = !hasRows
        countItem?.title = headerTitle(total: currentPorts.count, visible: visibleCount)
        rowSeparatorItem?.isHidden = !hasRows
    }

    private func headerTitle(total: Int, visible: Int) -> String {
        let label: String
        switch filter {
        case .active: label = "Puertos activos"
        case .favorites: label = "Favoritos activos"
        case .ignored: label = "Ignorados activos"
        }
        return "\(label)  (\(visible)/\(total))"
    }
}

// MARK: – MenuDelegate

private class MenuDelegate: NSObject, NSMenuDelegate {
    private let onWillOpen: () -> Void
    init(_ block: @escaping () -> Void) { self.onWillOpen = block }
    func menuWillOpen(_ menu: NSMenu) { onWillOpen() }
}
