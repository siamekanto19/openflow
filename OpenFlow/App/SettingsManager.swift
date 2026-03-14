import Foundation
import SwiftUI

/// Persists and exposes user settings using UserDefaults with @AppStorage-compatible keys
final class SettingsManager: ObservableObject {
    // MARK: - Keys
    private enum Keys {
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let recordingMode = "recordingMode"
        static let insertionMethod = "insertionMethod"
        static let formattingProfileRaw = "formattingProfile"
        static let language = "language"
        static let modelPath = "modelPath"
        static let selectedModelName = "selectedModelName"
        static let launchAtLogin = "launchAtLogin"
        static let showHUD = "showHUD"
    }

    // MARK: - Published Properties

    @Published var hotkeyKeyCode: UInt32 {
        didSet { UserDefaults.standard.set(hotkeyKeyCode, forKey: Keys.hotkeyKeyCode) }
    }

    @Published var hotkeyModifiers: UInt32 {
        didSet { UserDefaults.standard.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers) }
    }

    @Published var recordingMode: RecordingMode {
        didSet { UserDefaults.standard.set(recordingMode.rawValue, forKey: Keys.recordingMode) }
    }

    @Published var insertionMethod: InsertionMethod {
        didSet { UserDefaults.standard.set(insertionMethod.rawValue, forKey: Keys.insertionMethod) }
    }

    @Published var formattingProfile: FormattingProfile {
        didSet { UserDefaults.standard.set(formattingProfile.rawValue, forKey: Keys.formattingProfileRaw) }
    }

    @Published var language: String {
        didSet { UserDefaults.standard.set(language, forKey: Keys.language) }
    }

    @Published var modelPath: String {
        didSet { UserDefaults.standard.set(modelPath, forKey: Keys.modelPath) }
    }

    @Published var selectedModelName: String {
        didSet { UserDefaults.standard.set(selectedModelName, forKey: Keys.selectedModelName) }
    }

    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var showHUD: Bool {
        didSet { UserDefaults.standard.set(showHUD, forKey: Keys.showHUD) }
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard

        // Default hotkey: Control + Option + Space (keyCode 49 = space)
        let storedKeyCode = UInt32(defaults.integer(forKey: Keys.hotkeyKeyCode))
        self.hotkeyKeyCode = storedKeyCode == 0 ? 49 : storedKeyCode

        let storedModifiers = UInt32(defaults.integer(forKey: Keys.hotkeyModifiers))
        self.hotkeyModifiers = storedModifiers

        self.recordingMode = RecordingMode(rawValue: defaults.string(forKey: Keys.recordingMode) ?? "") ?? .toggle
        self.insertionMethod = InsertionMethod(rawValue: defaults.string(forKey: Keys.insertionMethod) ?? "") ?? .paste
        self.formattingProfile = FormattingProfile(rawValue: defaults.string(forKey: Keys.formattingProfileRaw) ?? "") ?? .naturalProse
        self.language = defaults.string(forKey: Keys.language) ?? "en"
        self.modelPath = defaults.string(forKey: Keys.modelPath) ?? ""
        self.selectedModelName = defaults.string(forKey: Keys.selectedModelName) ?? "ggml-base.en"
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.showHUD = defaults.object(forKey: Keys.showHUD) as? Bool ?? true
    }
}
