import AppKit

final class SettingsWindowController: NSWindowController {

    private var loginSwitch = NSSwitch()

    convenience init() {
        let w = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 130),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        w.title = "Preferencias — PortMonitor"
        w.titlebarAppearsTransparent = false
        w.isMovableByWindowBackground = true
        w.level = .floating        // flota sobre el menú y otras ventanas
        w.center()
        self.init(window: w)
        buildUI()
    }

    private func buildUI() {
        guard let cv = window?.contentView else { return }

        // — Fila: "Lanzar al iniciar el sistema" + switch —
        let label = NSTextField(labelWithString: "Lanzar al iniciar el sistema")
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false

        loginSwitch.state = LoginItemManager.isEnabled ? .on : .off
        loginSwitch.target = self
        loginSwitch.action = #selector(toggleLogin)
        loginSwitch.translatesAutoresizingMaskIntoConstraints = false

        // — Separador + versión al pie —
        let sep = NSBox(); sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let versionLabel = NSTextField(labelWithString: "PortMonitor \(version)")
        versionLabel.font = .systemFont(ofSize: 11)
        versionLabel.textColor = .tertiaryLabelColor
        versionLabel.translatesAutoresizingMaskIntoConstraints = false

        [label, loginSwitch, sep, versionLabel].forEach { cv.addSubview($0) }

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cv.leadingAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: cv.centerYAnchor, constant: -10),

            loginSwitch.trailingAnchor.constraint(equalTo: cv.trailingAnchor, constant: -20),
            loginSwitch.centerYAnchor.constraint(equalTo: label.centerYAnchor),

            sep.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: cv.bottomAnchor, constant: -30),

            versionLabel.centerXAnchor.constraint(equalTo: cv.centerXAnchor),
            versionLabel.bottomAnchor.constraint(equalTo: cv.bottomAnchor, constant: -10),
        ])
    }

    func show() {
        // Refresh switch state each time the panel opens
        loginSwitch.state = LoginItemManager.isEnabled ? .on : .off
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleLogin(_ sender: NSSwitch) {
        do {
            if sender.state == .on {
                try LoginItemManager.enable()
            } else {
                try LoginItemManager.disable()
            }
        } catch {
            sender.state = sender.state == .on ? .off : .on   // revert
            let alert = NSAlert()
            alert.messageText = "Error al modificar inicio automático"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}
