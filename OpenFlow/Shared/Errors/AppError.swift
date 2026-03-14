import Foundation

/// Unified error types across the application
enum AppError: LocalizedError {
    // Permissions
    case microphonePermissionDenied
    case accessibilityPermissionDenied

    // Audio
    case audioEngineStartFailed(String)
    case noAudioCaptured
    case audioExportFailed(String)

    // Transcription
    case noModelFound
    case modelLoadFailed(String)
    case transcriptionFailed(String)
    case emptyTranscript
    case engineNotInitialized

    // Insertion
    case insertionFailed(String)
    case focusedAppNotFound
    case pasteboardFailed

    // Data
    case databaseError(String)
    case migrationFailed(String)

    // General
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required. Please grant permission in System Settings → Privacy & Security → Microphone."
        case .accessibilityPermissionDenied:
            return "Accessibility access is required for text insertion. Please grant permission in System Settings → Privacy & Security → Accessibility."
        case .audioEngineStartFailed(let detail):
            return "Failed to start audio capture: \(detail)"
        case .noAudioCaptured:
            return "No audio was captured. Please check your microphone."
        case .audioExportFailed(let detail):
            return "Failed to export audio: \(detail)"
        case .noModelFound:
            return "No transcription model found. Please download a model in Settings."
        case .modelLoadFailed(let detail):
            return "Failed to load transcription model: \(detail)"
        case .transcriptionFailed(let detail):
            return "Transcription failed: \(detail)"
        case .emptyTranscript:
            return "No speech was detected in the recording."
        case .engineNotInitialized:
            return "Transcription engine is not ready. Please wait for model to load."
        case .insertionFailed(let detail):
            return "Failed to insert text: \(detail)"
        case .focusedAppNotFound:
            return "Could not detect the focused application."
        case .pasteboardFailed:
            return "Failed to access the system clipboard."
        case .databaseError(let detail):
            return "Database error: \(detail)"
        case .migrationFailed(let detail):
            return "Database migration failed: \(detail)"
        case .unknown(let detail):
            return "An unexpected error occurred: \(detail)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Open System Settings and enable microphone access for OpenFlow."
        case .accessibilityPermissionDenied:
            return "Open System Settings and enable accessibility access for OpenFlow."
        case .noModelFound:
            return "Go to Settings → Dictation to download a transcription model."
        case .noAudioCaptured:
            return "Make sure your microphone is connected and not muted."
        default:
            return nil
        }
    }
}
