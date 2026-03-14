import Foundation
import AppKit

/// Protocol for text insertion strategies
protocol InsertionStrategy {
    func insert(_ text: String) async throws
}

/// Inserts text via clipboard paste (⌘V)
final class PasteboardInsertionStrategy: InsertionStrategy {
    func insert(_ text: String) async throws {
        let pasteboard = NSPasteboard.general

        // Save current clipboard contents
        let previousContents = pasteboard.string(forType: .string)
        let previousChangeCount = pasteboard.changeCount

        // Set our text to clipboard
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw AppError.pasteboardFailed
        }

        // Brief delay to ensure pasteboard is ready
        try await Task.sleep(for: .milliseconds(50))

        // Simulate ⌘V
        simulatePaste()

        // Wait for paste to complete
        try await Task.sleep(for: .milliseconds(200))

        // Restore previous clipboard contents
        if let previous = previousContents, pasteboard.changeCount == previousChangeCount + 1 {
            pasteboard.clearContents()
            pasteboard.setString(previous, forType: .string)
        }

        AppLogger.insertion.info("Text inserted via paste strategy")
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down: ⌘V (keyCode 9 = V)
        let cmdVDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        cmdVDown?.flags = .maskCommand
        cmdVDown?.post(tap: .cghidEventTap)

        // Key up: ⌘V
        let cmdVUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        cmdVUp?.flags = .maskCommand
        cmdVUp?.post(tap: .cghidEventTap)
    }
}

/// Inserts text by simulating individual keystrokes
final class KeystrokeTypingStrategy: InsertionStrategy {
    func insert(_ text: String) async throws {
        let source = CGEventSource(stateID: .hidSystemState)

        for char in text {
            let str = String(char)

            guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) else {
                continue
            }

            var unicodeChars = Array(str.utf16)
            event.keyboardSetUnicodeString(stringLength: unicodeChars.count, unicodeString: &unicodeChars)
            event.post(tap: .cghidEventTap)

            // Key up
            guard let upEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
                continue
            }
            upEvent.keyboardSetUnicodeString(stringLength: unicodeChars.count, unicodeString: &unicodeChars)
            upEvent.post(tap: .cghidEventTap)

            // Small delay between keystrokes for reliability
            try await Task.sleep(for: .milliseconds(5))
        }

        AppLogger.insertion.info("Text inserted via keystroke strategy (\(text.count) chars)")
    }
}
