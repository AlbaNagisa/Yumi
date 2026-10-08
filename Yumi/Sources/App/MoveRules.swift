import Foundation

enum MoveRules {
    enum Offer: Equatable {
        case none, drag, move, replace, openInstalled
    }

    static func offer(bundlePath: String, home: String, installedExists: Bool, mineBuild: Int, installedBuild: Int) -> Offer {
        guard isElsewhere(bundlePath, home: home) else { return .none }
        if bundlePath.contains("/AppTranslocation/") { return .drag }
        guard installedExists else { return .move }
        return mineBuild > installedBuild ? .replace : .openInstalled
    }

    static func isElsewhere(_ path: String, home: String) -> Bool {
        if path.hasPrefix("/Applications/") || path.hasPrefix(home + "/Applications/") { return false }
        for mark in ["/DerivedData/", "/Build/Products/"] where path.contains(mark) { return false }
        return true
    }
}
