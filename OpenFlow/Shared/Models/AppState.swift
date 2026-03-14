import Foundation
import SwiftUI

// MARK: - Recording State

enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case inserting
    case success(String)
    case failure(String)

    var isActive: Bool {
        switch self {
        case .recording, .transcribing, .inserting:
            return true
        default:
            return false
        }
    }

    var statusText: String {
        switch self {
        case .idle: return "Ready"
        case .recording: return "Recording…"
        case .transcribing: return "Transcribing…"
        case .inserting: return "Inserting…"
        case .success: return "Done"
        case .failure(let msg): return "Error: \(msg)"
        }
    }

    var iconName: String {
        switch self {
        case .idle: return "waveform.circle.fill"
        case .recording: return "waveform"
        case .transcribing: return "brain.head.profile"
        case .inserting: return "text.cursor"
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Enums

enum InsertionMethod: String, Codable, CaseIterable, Identifiable {
    case paste
    case typing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .paste: return "Clipboard Paste"
        case .typing: return "Simulated Typing"
        }
    }
}

enum TranscriptStatus: String, Codable {
    case success
    case insertionFailed
    case transcriptionFailed
}

enum RecordingMode: String, Codable, CaseIterable, Identifiable {
    case holdToTalk
    case toggle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .holdToTalk: return "Hold to Talk"
        case .toggle: return "Toggle On/Off"
        }
    }
}

// MARK: - App State Store

@Observable
final class RecordingStateStore {
    var currentState: RecordingState = .idle
    var lastTranscript: String?
    var recordingStartTime: Date?
    var recordingDuration: TimeInterval = 0

    func startRecording() {
        currentState = .recording
        recordingStartTime = Date()
        recordingDuration = 0
    }

    func stopRecording() {
        if let start = recordingStartTime {
            recordingDuration = Date().timeIntervalSince(start)
        }
        currentState = .transcribing
    }

    func setTranscribing() {
        currentState = .transcribing
    }

    func setInserting() {
        currentState = .inserting
    }

    func setSuccess(_ transcript: String) {
        lastTranscript = transcript
        currentState = .success(transcript)

        // Auto-dismiss after 2 seconds
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if case .success = self.currentState {
                self.currentState = .idle
            }
        }
    }

    func setFailure(_ message: String) {
        currentState = .failure(message)

        // Auto-dismiss after 4 seconds
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if case .failure = self.currentState {
                self.currentState = .idle
            }
        }
    }

    func reset() {
        currentState = .idle
        recordingDuration = 0
        recordingStartTime = nil
    }
}
