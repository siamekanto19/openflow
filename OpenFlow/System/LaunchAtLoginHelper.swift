import Foundation
import ServiceManagement

/// Helper for enabling/disabling launch at login using SMAppService (macOS 13+)
enum LaunchAtLoginHelper {
    static func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    AppLogger.general.info("Launch at login enabled")
                } else {
                    try SMAppService.mainApp.unregister()
                    AppLogger.general.info("Launch at login disabled")
                }
            } catch {
                AppLogger.general.error("Failed to set launch at login: \(error.localizedDescription)")
            }
        }
    }

    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
}
