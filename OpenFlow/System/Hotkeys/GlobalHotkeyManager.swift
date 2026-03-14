import Foundation
import AppKit
import Carbon
import HotKey

/// Manages global hotkey registration for push-to-talk and toggle modes
@MainActor
final class GlobalHotkeyManager {
    private var hotKey: HotKey?
    private let settingsManager: SettingsManager
    private var isRecording = false

    var onRecordingStarted: (() -> Void)?
    var onRecordingStopped: (() -> Void)?

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }

    func registerHotkey() {
        unregisterHotkey()

        // Default: Control + Option + Space
        let key: Key = keyFromCode(settingsManager.hotkeyKeyCode) ?? .space
        let modifiers: NSEvent.ModifierFlags = [.control, .option]

        hotKey = HotKey(key: key, modifiers: modifiers)

        hotKey?.keyDownHandler = { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleKeyDown()
            }
        }

        hotKey?.keyUpHandler = { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleKeyUp()
            }
        }

        AppLogger.hotkey.info("Global hotkey registered")
    }

    func unregisterHotkey() {
        hotKey = nil
        isRecording = false
        AppLogger.hotkey.info("Global hotkey unregistered")
    }

    /// Reset the internal recording state flag (e.g. after external cancel/stop)
    func resetRecordingState() {
        isRecording = false
    }

    func updateHotkey(keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        settingsManager.hotkeyKeyCode = keyCode
        registerHotkey()
    }

    // MARK: - Key Event Handlers

    private func handleKeyDown() {
        switch settingsManager.recordingMode {
        case .holdToTalk:
            // Hold mode: start on key down
            if !isRecording {
                isRecording = true
                onRecordingStarted?()
                AppLogger.hotkey.info("Hold-to-talk: recording started")
            }
        case .toggle:
            // Toggle mode: toggle on each key down
            if isRecording {
                isRecording = false
                onRecordingStopped?()
                AppLogger.hotkey.info("Toggle mode: recording stopped")
            } else {
                isRecording = true
                onRecordingStarted?()
                AppLogger.hotkey.info("Toggle mode: recording started")
            }
        }
    }

    private func handleKeyUp() {
        switch settingsManager.recordingMode {
        case .holdToTalk:
            // Hold mode: stop on key up
            if isRecording {
                isRecording = false
                onRecordingStopped?()
                AppLogger.hotkey.info("Hold-to-talk: recording stopped")
            }
        case .toggle:
            // Toggle mode: do nothing on key up
            break
        }
    }

    // MARK: - Key Code Mapping

    private func keyFromCode(_ keyCode: UInt32) -> Key? {
        // Map common key codes to HotKey's Key enum
        switch keyCode {
        case 49: return .space
        case 36: return .return
        case 48: return .tab
        case 0: return .a
        case 1: return .s
        case 2: return .d
        case 3: return .f
        case 5: return .g
        case 4: return .h
        case 38: return .j
        case 40: return .k
        case 37: return .l
        case 6: return .z
        case 7: return .x
        case 8: return .c
        case 9: return .v
        case 11: return .b
        case 45: return .n
        case 46: return .m
        case 12: return .q
        case 13: return .w
        case 14: return .e
        case 15: return .r
        case 17: return .t
        case 16: return .y
        case 32: return .u
        case 34: return .i
        case 31: return .o
        case 35: return .p
        default: return nil
        }
    }
}
