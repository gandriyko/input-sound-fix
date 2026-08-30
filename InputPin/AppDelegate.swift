import AppKit
import OSLog

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.inputpin.app", category: "Application")
    private var audioManager: AudioManager?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.notice("InputPin application did finish launching")
        NSApp.setActivationPolicy(.accessory)

        let manager = AudioManager(settings: Settings())
        audioManager = manager
        statusBarController = StatusBarController(
            audioManager: manager,
            loginItemManager: LoginItemManager()
        )
        manager.startMonitoring()
        logger.notice("InputPin monitoring started")
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.notice("InputPin application will terminate")
        audioManager?.stopMonitoring()
    }
}
