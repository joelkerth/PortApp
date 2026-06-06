import AppKit

final class PortMenuItemView: NSView {
    var onOpen: (() -> Void)?
    var onKill: (() -> Void)?

    static let rowHeight: CGFloat = 30
    static let menuWidth: CGFloat = 280

    private let nameLabel = NSTextField(labelWithString: "")
    private let openBtn: NSButton
    private let killBtn: NSButton

    init(info: PortInfo) {
        openBtn = Self.iconButton(symbol: "safari",           tint: .systemBlue)
        killBtn = Self.iconButton(symbol: "xmark.circle.fill", tint: .systemRed)
        super.init(frame: NSRect(x: 0, y: 0, width: Self.menuWidth, height: Self.rowHeight))
        wantsLayer = true

        nameLabel.stringValue = ":\(info.port)   \(info.processName)"
        nameLabel.font = .systemFont(ofSize: 13)
        nameLabel.textColor = .labelColor
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        openBtn.action = #selector(didOpen)
        openBtn.target = self
        killBtn.action = #selector(didKill)
        killBtn.target = self

        [nameLabel, openBtn, killBtn].forEach { addSubview($0) }

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: openBtn.leadingAnchor, constant: -8),

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

    // MARK: – Hover highlight

    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.selectedContentBackgroundColor.withAlphaComponent(0.12).cgColor
    }

    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = .clear
    }

    // MARK: – Actions

    @objc private func didOpen() { onOpen?() }
    @objc private func didKill() { onKill?() }

    // MARK: – Factory

    private static func iconButton(symbol: String, tint: NSColor) -> NSButton {
        let btn = NSButton()
        let cfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        btn.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg)
        btn.contentTintColor = tint
        btn.isBordered = false
        btn.bezelStyle = .inline
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }
}
