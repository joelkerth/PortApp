import Foundation

enum PortFilter: Int {
    case active = 0
    case favorites = 1
    case ignored = 2
}

enum PortPreferences {
    private static let favoriteKey = "favoriteProcessIdentities"
    private static let ignoredKey = "ignoredProcessIdentities"

    static var favorites: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: favoriteKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue).sorted(), forKey: favoriteKey) }
    }

    static var ignored: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: ignoredKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue).sorted(), forKey: ignoredKey) }
    }

    static func isFavorite(_ info: PortInfo) -> Bool {
        favorites.contains(info.identity)
    }

    static func isIgnored(_ info: PortInfo) -> Bool {
        ignored.contains(info.identity)
    }

    static func toggleFavorite(_ info: PortInfo) {
        var values = favorites
        if values.contains(info.identity) {
            values.remove(info.identity)
        } else {
            values.insert(info.identity)
        }
        favorites = values
    }

    static func toggleIgnored(_ info: PortInfo) {
        var values = ignored
        if values.contains(info.identity) {
            values.remove(info.identity)
        } else {
            values.insert(info.identity)
        }
        ignored = values
    }
}
