import Foundation

/// Coordinates text insertion using the configured strategy with fallback
final class InsertionCoordinator {
    private let pasteStrategy = PasteboardInsertionStrategy()
    private let typingStrategy = KeystrokeTypingStrategy()

    func insert(_ text: String, method: InsertionMethod) async throws {
        AppLogger.insertion.info("Inserting text via \(method.rawValue) (\(text.count) chars)")

        switch method {
        case .paste:
            do {
                try await pasteStrategy.insert(text)
            } catch {
                AppLogger.insertion.warning("Paste insertion failed, falling back to typing: \(error.localizedDescription)")
                try await typingStrategy.insert(text)
            }
        case .typing:
            try await typingStrategy.insert(text)
        }
    }
}
