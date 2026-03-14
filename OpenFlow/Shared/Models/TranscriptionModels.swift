import Foundation

// MARK: - Transcription Options

struct TranscriptionOptions {
    let languageCode: String
    let modelPath: String
    let enableTimestamps: Bool

    static var `default`: TranscriptionOptions {
        TranscriptionOptions(
            languageCode: "en",
            modelPath: "",
            enableTimestamps: false
        )
    }
}

// MARK: - Transcription Result

struct TranscriptionResult {
    let rawText: String
    let segments: [TranscriptSegment]
    let durationMs: Int
}

struct TranscriptSegment {
    let text: String
    let startMs: Int
    let endMs: Int
}

// MARK: - Transcript Record (persisted)

struct TranscriptRecord: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let createdAt: Date
    let rawText: String
    let processedText: String
    let sourceAppName: String?
    let durationMs: Int
    let languageCode: String
    let insertionMethod: String
    let status: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        rawText: String,
        processedText: String,
        sourceAppName: String? = nil,
        durationMs: Int,
        languageCode: String = "en",
        insertionMethod: InsertionMethod = .paste,
        status: TranscriptStatus = .success
    ) {
        self.id = id
        self.createdAt = createdAt
        self.rawText = rawText
        self.processedText = processedText
        self.sourceAppName = sourceAppName
        self.durationMs = durationMs
        self.languageCode = languageCode
        self.insertionMethod = insertionMethod.rawValue
        self.status = status.rawValue
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var formattedDuration: String {
        let seconds = Double(durationMs) / 1000.0
        if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return "\(minutes)m \(secs)s"
        }
    }
}

// MARK: - Replacement Rule (persisted)

struct ReplacementRule: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var triggerText: String
    var replacementText: String
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        triggerText: String,
        replacementText: String,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.triggerText = triggerText
        self.replacementText = replacementText
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
