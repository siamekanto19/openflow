import Foundation
import AVFoundation

/// Protocol for audio capture
protocol AudioCaptureServiceProtocol: AnyObject {
    func startRecording() throws
    func stopRecording() async throws -> [Float]
    func cancelRecording()
}

/// Captures microphone audio using AVAudioEngine, outputs 16kHz mono Float arrays
final class AudioCaptureService: AudioCaptureServiceProtocol {
    private let audioEngine = AVAudioEngine()
    private var audioBuffer: [Float] = []
    private var isRecording = false
    private let bufferQueue = DispatchQueue(label: "com.openflow.audiobuffer", qos: .userInteractive)

    /// Target sample rate for whisper.cpp
    private let targetSampleRate: Double = 16000.0

    func startRecording() throws {
        guard !isRecording else {
            AppLogger.audio.warning("Already recording")
            return
        }

        // Clear buffer
        bufferQueue.sync { audioBuffer.removeAll() }

        let inputNode = audioEngine.inputNode

        // Get the native hardware format
        let hardwareFormat = inputNode.inputFormat(forBus: 0)
        guard hardwareFormat.sampleRate > 0, hardwareFormat.channelCount > 0 else {
            throw AppError.audioEngineStartFailed("Invalid audio input format (sampleRate=\(hardwareFormat.sampleRate), channels=\(hardwareFormat.channelCount)). Check microphone connection.")
        }

        AppLogger.audio.info("Input format: \(hardwareFormat.sampleRate)Hz, \(hardwareFormat.channelCount) channels")

        // Install tap on input node in native format
        let sampleRate = hardwareFormat.sampleRate
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer, inputSampleRate: sampleRate)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            AppLogger.audio.info("Audio engine started successfully")
        } catch {
            inputNode.removeTap(onBus: 0)
            throw AppError.audioEngineStartFailed(error.localizedDescription)
        }
    }

    func stopRecording() async throws -> [Float] {
        guard isRecording else {
            AppLogger.audio.warning("stopRecording called but not recording")
            throw AppError.noAudioCaptured
        }

        // Brief pause to let any final audio buffers arrive
        try? await Task.sleep(for: .milliseconds(100))

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false

        let capturedFrames: [Float] = bufferQueue.sync {
            let frames = audioBuffer
            audioBuffer.removeAll()
            return frames
        }

        let sampleCount = capturedFrames.count
        let duration = Double(sampleCount) / 16000.0
        AppLogger.audio.info("Audio engine stopped, captured \(sampleCount) samples (\(String(format: "%.1f", duration))s)")

        return capturedFrames
    }

    /// Cancel recording — stop engine, discard buffer, no transcription
    func cancelRecording() {
        guard isRecording else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false
        bufferQueue.sync { audioBuffer.removeAll() }
        AppLogger.audio.info("Recording cancelled, buffer discarded")
    }

    // MARK: - Audio Processing

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, inputSampleRate: Double) {
        guard let channelData = buffer.floatChannelData else { return }

        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }

        let channelCount = Int(buffer.format.channelCount)

        // Mix down to mono if stereo
        var monoSamples = [Float](repeating: 0, count: frameCount)
        if channelCount == 1 {
            monoSamples = Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))
        } else {
            for i in 0..<frameCount {
                var sum: Float = 0
                for ch in 0..<channelCount {
                    sum += channelData[ch][i]
                }
                monoSamples[i] = sum / Float(channelCount)
            }
        }

        // Resample to 16kHz if needed
        let ratio = targetSampleRate / inputSampleRate
        let resampled: [Float]
        if abs(ratio - 1.0) < 0.001 {
            resampled = monoSamples
        } else {
            let outputCount = max(1, Int(Double(frameCount) * ratio))
            resampled = resample(monoSamples, from: frameCount, to: outputCount)
        }

        bufferQueue.sync {
            audioBuffer.append(contentsOf: resampled)
        }
    }

    /// Simple linear interpolation resampler
    private func resample(_ input: [Float], from inputCount: Int, to outputCount: Int) -> [Float] {
        guard inputCount > 1 && outputCount > 0 else { return [] }

        var output = [Float](repeating: 0, count: outputCount)
        let ratio = Double(inputCount - 1) / Double(max(1, outputCount - 1))

        for i in 0..<outputCount {
            let srcIndex = Double(i) * ratio
            let srcIndexInt = Int(srcIndex)
            let fraction = Float(srcIndex - Double(srcIndexInt))

            if srcIndexInt + 1 < inputCount {
                output[i] = input[srcIndexInt] * (1 - fraction) + input[srcIndexInt + 1] * fraction
            } else {
                output[i] = input[min(srcIndexInt, inputCount - 1)]
            }
        }

        return output
    }
}
