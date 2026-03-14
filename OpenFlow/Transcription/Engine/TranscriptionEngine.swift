import Foundation

/// Protocol for speech-to-text engines — allows swapping implementations
protocol TranscriptionEngine: AnyObject {
    /// Load the transcription model into memory
    func loadModel() async throws

    /// Transcribe audio frames (16kHz mono Float array)
    func transcribe(audioFrames: [Float], options: TranscriptionOptions) async throws -> TranscriptionResult

    /// Whether the engine is ready for transcription
    var isModelLoaded: Bool { get }
}
