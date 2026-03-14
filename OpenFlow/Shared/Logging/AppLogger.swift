import Foundation
import os

/// Structured logging using os.Logger with subsystem categories
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.openflow.app"

    static let general = Logger(subsystem: subsystem, category: "general")
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let transcription = Logger(subsystem: subsystem, category: "transcription")
    static let insertion = Logger(subsystem: subsystem, category: "insertion")
    static let hotkey = Logger(subsystem: subsystem, category: "hotkey")
    static let permissions = Logger(subsystem: subsystem, category: "permissions")
    static let database = Logger(subsystem: subsystem, category: "database")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
