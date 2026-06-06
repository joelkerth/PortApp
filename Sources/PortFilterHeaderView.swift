import AppKit

final class PortFilterHeaderView: NSView, NSSearchFieldDelegate {
    var onSearch: ((String) -> Void)?
    var onFilter: ((PortFilter) -> Void)?

    static let height: CGFloat = 68

    private let searchField = NSSearchField()
    private let filterControl = NSSegmentedControl(labels: ["Activos", "Favoritos", "Ignorados"], trackingMode: .selectOne, target: nil, action: nil)

    init(searchText: String, filter: PortFilter, width: CGFloat = PortMenuItemView.menuWidth) {
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: Self.height))

        searchField.stringValue = searchText
        searchField.placeholderString = "Buscar puerto, proceso o framework"
        searchField.delegate = self
        searchField.target = self
        searchField.action = #selector(searchChanged)
        searchField.translatesAutoresizingMaskIntoConstraints = false

        filterControl.selectedSegment = filter.rawValue
        filterControl.target = self
        filterControl.action = #selector(filterChanged)
        filterControl.translatesAutoresizingMaskIntoConstraints = false

        addSubview(searchField)
        addSubview(filterControl)

        NSLayoutConstraint.activate([
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            searchField.topAnchor.constraint(equalTo: topAnchor, constant: 8),

            filterControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            filterControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            filterControl.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func controlTextDidChange(_ obj: Notification) {
        onSearch?(searchField.stringValue)
    }

    @objc private func searchChanged() {
        onSearch?(searchField.stringValue)
    }

    @objc private func filterChanged() {
        onFilter?(PortFilter(rawValue: filterControl.selectedSegment) ?? .active)
    }
}
