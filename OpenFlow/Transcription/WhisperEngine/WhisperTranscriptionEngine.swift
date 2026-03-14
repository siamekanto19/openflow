import Foundation
import SwiftWhisper

/// Whisper.cpp-based transcription engine using SwiftWhisper
final class WhisperTranscriptionEngine: TranscriptionEngine {
    private var whisper: Whisper?
    private let modelManager: ModelManager
    private(set) var isModelLoaded = false

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }

    func loadModel() async throws {
        guard let modelURL = modelManager.activeModelURL else {
            // Try to find any available model
            let models = modelManager.availableModels()
            guard let firstModel = models.first else {
                throw AppError.noModelFound
            }
            try await loadModel(at: firstModel.url)
            return
        }

        try await loadModel(at: modelURL)
    }

    private func loadModel(at url: URL) async throws {
        AppLogger.transcription.info("Loading model from: \(url.path)")

        whisper = Whisper(fromFileURL: url)
        isModelLoaded = true
        AppLogger.transcription.info("Model loaded successfully")
    }

    func transcribe(audioFrames: [Float], options: TranscriptionOptions) async throws -> TranscriptionResult {
        guard let whisper = whisper, isModelLoaded else {
            throw AppError.engineNotInitialized
        }

        AppLogger.transcription.info("Starting transcription of \(audioFrames.count) frames (~\(String(format: "%.1f", Double(audioFrames.count) / 16000.0))s of audio)")
        let startTime = Date()

        do {
            let segments = try await whisper.transcribe(audioFrames: audioFrames)
            let duration = Date().timeIntervalSince(startTime)

            // Filter out blank/noise markers that whisper.cpp sometimes outputs
            let filteredSegments = segments.filter { segment in
                let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let isBlank = text.isEmpty
                    || text.contains("[blank_audio]")
                    || text.contains("[silence]")
                    || text.contains("(silence)")
                    || text == "."
                    || text == "..."
                    || text.hasPrefix("[") && text.hasSuffix("]")
                    || text.hasPrefix("(") && text.hasSuffix(")")
                return !isBlank
            }

            let rawText = filteredSegments.map { $0.text }.joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            AppLogger.transcription.info("Transcription completed in \(Int(duration * 1000))ms — raw segments: \(segments.count), filtered: \(filteredSegments.count), text: \"\(rawText)\"")

            let transcriptSegments = filteredSegments.map { segment in
                TranscriptSegment(
                    text: segment.text,
                    startMs: Int(segment.startTime * 1000),
                    endMs: Int(segment.endTime * 1000)
                )
            }

            return TranscriptionResult(
                rawText: rawText,
                segments: transcriptSegments,
                durationMs: Int(duration * 1000)
            )
        } catch {
            throw AppError.transcriptionFailed(error.localizedDescription)
        }
    }
}
