import Foundation

final class Settings {
    private enum Key {
        static let pinEnabled = "pinEnabled"
        static let pinnedDeviceUID = "pinnedDeviceUID"
        static let pinnedDeviceName = "pinnedDeviceName"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var pinEnabled: Bool {
        get { defaults.bool(forKey: Key.pinEnabled) }
        set { defaults.set(newValue, forKey: Key.pinEnabled) }
    }

    var pinnedDeviceUID: String? {
        get { defaults.string(forKey: Key.pinnedDeviceUID) }
        set { defaults.set(newValue, forKey: Key.pinnedDeviceUID) }
    }

    var pinnedDeviceName: String? {
        get { defaults.string(forKey: Key.pinnedDeviceName) }
        set { defaults.set(newValue, forKey: Key.pinnedDeviceName) }
    }
}
