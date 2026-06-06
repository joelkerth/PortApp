import AppKit

final class MenuFooterView: NSView {
    var onSettings: (() -> Void)?
    var onRefresh:  (() -> Void)?
    var onQuit:     (() -> Void)?

    static let height: CGFloat = 34

    private let settingsBtn: NSButton
    private let refreshBtn:  NSButton
    private let quitBtn:     NSButton

    init(width: CGFloat = PortMenuItemView.menuWidth) {
        settingsBtn = Self.icon("gearshape",       tint: .secondaryLabelColor)
        refreshBtn  = Self.icon("arrow.clockwise", tint: .secondaryLabelColor)
        quitBtn     = Self.icon("power",           tint: .secondaryLabelColor)
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: Self.height))
        wantsLayer = true

        settingsBtn.action = #selector(didSettings); settingsBtn.target = self
        refreshBtn.action  = #selector(didRefresh);  refreshBtn.target  = self
        quitBtn.action     = #selector(didQuit);     quitBtn.target     = self

        [settingsBtn, refreshBtn, quitBtn].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        // Separator line at top
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sep)

        let btnSize: CGFloat = 20
        NSLayoutConstraint.activate([
            sep.leadingAnchor.constraint(equalTo: leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: trailingAnchor),
            sep.topAnchor.constraint(equalTo: topAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1),

            // Settings icon — left side
            settingsBtn.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            settingsBtn.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1),
            settingsBtn.widthAnchor.constraint(equalToConstant: btnSize),
            settingsBtn.heightAnchor.constraint(equalToConstant: btnSize),

            // Quit icon — right edge
            quitBtn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            quitBtn.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1),
            quitBtn.widthAnchor.constraint(equalToConstant: btnSize),
            quitBtn.heightAnchor.constraint(equalToConstant: btnSize),

            // Refresh icon — left of quit
            refreshBtn.trailingAnchor.constraint(equalTo: quitBtn.leadingAnchor, constant: -10),
            refreshBtn.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1),
            refreshBtn.widthAnchor.constraint(equalToConstant: btnSize),
            refreshBtn.heightAnchor.constraint(equalToConstant: btnSize),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func didSettings() { onSettings?() }
    @objc private func didRefresh()  { onRefresh?()  }
    @objc private func didQuit()     { onQuit?()     }

    private static func icon(_ symbol: String, tint: NSColor) -> NSButton {
        let btn = NSButton()
        let cfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        btn.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg)
        btn.contentTintColor = tint
        btn.isBordered = false
        btn.bezelStyle = .inline
        return btn
    }
}
