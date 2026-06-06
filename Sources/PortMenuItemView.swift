import AppKit

final class PortMenuItemView: NSView {
    var onOpen: (() -> Void)?
    var onKill: (() -> Void)?
    var onFavorite: (() -> Void)?
    var onIgnore: (() -> Void)?

    static let rowHeight: CGFloat = 58
    static let menuWidth: CGFloat = 520

    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let favoriteBtn: NSButton
    private let ignoreBtn: NSButton
    private let openBtn: NSButton
    private let killBtn: NSButton

    init(info: PortInfo) {
        favoriteBtn = Self.iconButton(
            symbol: PortPreferences.isFavorite(info) ? "star.fill" : "star",
            tint: PortPreferences.isFavorite(info) ? .systemYellow : .secondaryLabelColor
        )
        ignoreBtn = Self.iconButton(
            symbol: PortPreferences.isIgnored(info) ? "eye" : "eye.slash",
            tint: PortPreferences.isIgnored(info) ? .systemBlue : .secondaryLabelColor
        )
        openBtn = Self.iconButton(symbol: "safari", tint: .systemBlue)
        killBtn = Self.iconButton(symbol: "xmark.circle.fill", tint: .systemRed)
        super.init(frame: NSRect(x: 0, y: 0, width: Self.menuWidth, height: Self.rowHeight))
        wantsLayer = true

        let framework = info.framework.map { "  \($0)" } ?? ""
        titleLabel.stringValue = ":\(info.port)\(framework)  \(info.processName)"
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        detailLabel.stringValue = info.executablePath.isEmpty ? info.command : info.executablePath
        detailLabel.toolTip = info.command.isEmpty ? detailLabel.stringValue : info.command
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.lineBreakMode = .byTruncatingMiddle
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.stringValue = info.elapsed.isEmpty ? "" : "activo \(info.elapsed)"
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        timeLabel.textColor = .tertiaryLabelColor
        timeLabel.alignment = .right
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        favoriteBtn.action = #selector(didFavorite)
        favoriteBtn.target = self
        ignoreBtn.action = #selector(didIgnore)
        ignoreBtn.target = self
        openBtn.action = #selector(didOpen)
        openBtn.target = self
        killBtn.action = #selector(didKill)
        killBtn.target = self

        [titleLabel, detailLabel, timeLabel, favoriteBtn, ignoreBtn, openBtn, killBtn].forEach { addSubview($0) }

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: favoriteBtn.leadingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 9),

            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -10),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            timeLabel.trailingAnchor.constraint(equalTo: favoriteBtn.leadingAnchor, constant: -10),
            timeLabel.centerYAnchor.constraint(equalTo: detailLabel.centerYAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 88),

            favoriteBtn.trailingAnchor.constraint(equalTo: ignoreBtn.leadingAnchor, constant: -8),
            favoriteBtn.centerYAnchor.constraint(equalTo: centerYAnchor),
            favoriteBtn.widthAnchor.constraint(equalToConstant: 20),
            favoriteBtn.heightAnchor.constraint(equalToConstant: 20),

            ignoreBtn.trailingAnchor.constraint(equalTo: openBtn.leadingAnchor, constant: -8),
            ignoreBtn.centerYAnchor.constraint(equalTo: centerYAnchor),
            ignoreBtn.widthAnchor.constraint(equalToConstant: 20),
            ignoreBtn.heightAnchor.constraint(equalToConstant: 20),

            openBtn.trailingAnchor.constraint(equalTo: killBtn.leadingAnchor, constant: -8),
            openBtn.centerYAnchor.constraint(equalTo: centerYAnchor),
            openBtn.widthAnchor.constraint(equalToConstant: 20),
            openBtn.heightAnchor.constraint(equalToConstant: 20),

            killBtn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            killBtn.centerYAnchor.constraint(equalTo: centerYAnchor),
            killBtn.widthAnchor.constraint(equalToConstant: 20),
            killBtn.heightAnchor.constraint(equalToConstant: 20),
        ])

        // Use .inVisibleRect so the tracking area auto-resizes with the view
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    required init?(coder: NSCoder) { fatalError() }

    func refreshPreferenceState(isFavorite: Bool, isIgnored: Bool) {
        favoriteBtn.image = Self.iconImage(symbol: isFavorite ? "star.fill" : "star")
        favoriteBtn.contentTintColor = isFavorite ? .systemYellow : .secondaryLabelColor

        ignoreBtn.image = Self.iconImage(symbol: isIgnored ? "eye" : "eye.slash")
        ignoreBtn.contentTintColor = isIgnored ? .systemBlue : .secondaryLabelColor
    }

    // MARK: – Hover highlight

    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.selectedContentBackgroundColor.withAlphaComponent(0.12).cgColor
    }

    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = .clear
    }

    // MARK: – Actions

    @objc private func didFavorite() { onFavorite?() }
    @objc private func didIgnore() { onIgnore?() }
    @objc private func didOpen() { onOpen?() }
    @objc private func didKill() { onKill?() }

    // MARK: – Factory

    private static func iconButton(symbol: String, tint: NSColor) -> NSButton {
        let btn = NSButton()
        btn.image = iconImage(symbol: symbol)
        btn.contentTintColor = tint
        btn.isBordered = false
        btn.bezelStyle = .inline
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    private static func iconImage(symbol: String) -> NSImage? {
        let cfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        return NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg)
    }
}
