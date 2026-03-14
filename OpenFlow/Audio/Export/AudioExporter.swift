import Foundation
import AVFoundation

/// Exports PCM audio frames to a temporary WAV file (for fallback/debugging)
enum AudioExporter {
    /// Saves Float audio frames (16kHz mono) to a WAV file at the specified URL
    static func exportToWAV(frames: [Float], sampleRate: Double = 16000.0, to url: URL) throws {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames.count)) else {
            throw AppError.audioExportFailed("Failed to create audio buffer")
        }

        buffer.frameLength = AVAudioFrameCount(frames.count)
        let channelData = buffer.floatChannelData![0]
        for i in 0..<frames.count {
            channelData[i] = frames[i]
        }

        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: buffer)
            AppLogger.audio.info("Audio exported to \(url.path)")
        } catch {
            throw AppError.audioExportFailed(error.localizedDescription)
        }
    }

    /// Creates a temporary WAV file URL
    static func temporaryWAVURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "whisper_recording_\(UUID().uuidString).wav"
        return tempDir.appendingPathComponent(filename)
    }

    /// Cleans up old temporary recordings
    static func cleanupTemporaryFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: nil
        ) else { return }

        for url in contents where url.lastPathComponent.hasPrefix("whisper_recording_") {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
