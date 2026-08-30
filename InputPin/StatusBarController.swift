import AppKit
import OSLog

final class StatusBarController: NSObject, NSMenuDelegate {
    private let audioManager: AudioManager
    private let loginItemManager: LoginItemManager
    private let statusItem: NSStatusItem
    private let logger = Logger(subsystem: "com.inputpin.app", category: "StatusBar")
    private let menu = NSMenu()
    private let pinItem = NSMenuItem(title: "Pin Input", action: #selector(togglePin), keyEquivalent: "")
    private let deviceItem = NSMenuItem(title: "Input Device", action: nil, keyEquivalent: "")
    private let deviceMenu = NSMenu(title: "Input Device")
    private let launchAtLoginItem = NSMenuItem(
        title: "Launch at Login",
        action: #selector(toggleLaunchAtLogin),
        keyEquivalent: ""
    )

    private var state = AudioState(
        devices: [],
        defaultDeviceUID: nil,
        pinEnabled: false,
        pinnedDeviceUID: nil,
        pinnedDeviceName: nil
    )

    init(audioManager: AudioManager, loginItemManager: LoginItemManager) {
        self.audioManager = audioManager
        self.loginItemManager = loginItemManager
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        configureMenu()
        if statusItem.button == nil {
            logger.error("Failed to create the InputPin status-bar button")
        } else {
            logger.notice("Created the InputPin status-bar button")
        }
        audioManager.onStateChange = { [weak self] state in
            self?.apply(state)
        }
    }

    private func configureMenu() {
        let titleItem = NSMenuItem(title: "InputPin", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        pinItem.target = self
        menu.addItem(pinItem)

        deviceItem.submenu = deviceMenu
        menu.addItem(deviceItem)

        menu.addItem(.separator())

        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit InputPin", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.delegate = self
        statusItem.menu = menu
        updateStatusIcon(pinEnabled: false)
        updateLaunchAtLoginItem()
    }

    private func apply(_ state: AudioState) {
        self.state = state
        pinItem.state = state.pinEnabled ? .on : .off
        updateStatusIcon(pinEnabled: state.pinEnabled)
        rebuildDeviceMenu(with: state.devices)
    }

    private func rebuildDeviceMenu(with devices: [AudioDevice]) {
        deviceMenu.removeAllItems()

        if state.pinEnabled,
           let pinnedUID = state.pinnedDeviceUID,
           !devices.contains(where: { $0.uid == pinnedUID }) {
            let pinnedName = state.pinnedDeviceName ?? "Saved Input Device"
            let pinnedItem = NSMenuItem(
                title: "Pinned: \(pinnedName) — Unavailable",
                action: nil,
                keyEquivalent: ""
            )
            pinnedItem.isEnabled = false
            deviceMenu.addItem(pinnedItem)
            if !devices.isEmpty {
                deviceMenu.addItem(.separator())
            }
        }

        if devices.isEmpty {
            let unavailableItem = NSMenuItem(title: "No Input Devices", action: nil, keyEquivalent: "")
            unavailableItem.isEnabled = false
            deviceMenu.addItem(unavailableItem)
            return
        }

        for device in devices {
            let item = NSMenuItem(title: device.name, action: #selector(selectDevice(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = device.uid
            item.state = device.uid == state.defaultDeviceUID ? .on : .off
            deviceMenu.addItem(item)
        }
    }

    private func updateStatusIcon(pinEnabled: Bool) {
        let symbolName = pinEnabled ? "mic.fill" : "mic.slash"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "InputPin")
        image?.isTemplate = true
        image?.size = NSSize(width: 16, height: 16)

        guard let button = statusItem.button else { return }
        button.image = image
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.title = ""
        button.toolTip = pinEnabled ? "InputPin: Pin On" : "InputPin: Pin Off"
    }

    @objc private func togglePin() {
        audioManager.setPinEnabled(!state.pinEnabled)
    }

    @objc private func selectDevice(_ sender: NSMenuItem) {
        guard let uid = sender.representedObject as? String else { return }
        audioManager.selectInputDevice(uid: uid)
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateLaunchAtLoginItem()
    }

    private func updateLaunchAtLoginItem() {
        switch loginItemManager.status {
        case .enabled:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .on
            launchAtLoginItem.isEnabled = true
        case .disabled:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .off
            launchAtLoginItem.isEnabled = true
        case .requiresApproval:
            launchAtLoginItem.title = "Launch at Login — Approval Required"
            launchAtLoginItem.state = .off
            launchAtLoginItem.isEnabled = true
        case .unavailable:
            launchAtLoginItem.title = "Launch at Login — Unavailable"
            launchAtLoginItem.state = .off
            launchAtLoginItem.isEnabled = false
        }
    }

    @objc private func toggleLaunchAtLogin() {
        let shouldEnable = loginItemManager.status != .enabled
        _ = loginItemManager.setEnabled(shouldEnable)
        updateLaunchAtLoginItem()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
