import Foundation
import AppKit

/// Orchestrates the entire dictation flow: hotkey → capture → transcribe → process → insert
@MainActor
final class AppCoordinator {
    private let stateStore: RecordingStateStore
    private let hotkeyManager: GlobalHotkeyManager
    private let audioCaptureService: AudioCaptureServiceProtocol
    private let transcriptionEngine: TranscriptionEngine
    private let transcriptProcessor: TranscriptProcessor
    private let insertionCoordinator: InsertionCoordinator
    private let transcriptRepository: TranscriptRepository
    private let settingsManager: SettingsManager
    private let permissionCoordinator: PermissionCoordinator
    private var hudController: FloatingHUDController?
    private var modelReloadObserver: NSObjectProtocol?
    private var hudCancelObserver: NSObjectProtocol?
    private var hudStopObserver: NSObjectProtocol?

    init(
        stateStore: RecordingStateStore,
        hotkeyManager: GlobalHotkeyManager,
        audioCaptureService: AudioCaptureServiceProtocol,
        transcriptionEngine: TranscriptionEngine,
        transcriptProcessor: TranscriptProcessor,
        insertionCoordinator: InsertionCoordinator,
        transcriptRepository: TranscriptRepository,
        settingsManager: SettingsManager,
        permissionCoordinator: PermissionCoordinator
    ) {
        self.stateStore = stateStore
        self.hotkeyManager = hotkeyManager
        self.audioCaptureService = audioCaptureService
        self.transcriptionEngine = transcriptionEngine
        self.transcriptProcessor = transcriptProcessor
        self.insertionCoordinator = insertionCoordinator
        self.transcriptRepository = transcriptRepository
        self.settingsManager = settingsManager
        self.permissionCoordinator = permissionCoordinator
    }

    func setup() {
        // Initialize HUD
        hudController = FloatingHUDController(stateStore: stateStore)

        // Register hotkey handlers
        hotkeyManager.onRecordingStarted = { [weak self] in
            Task { @MainActor in
                self?.startDictation()
            }
        }
        hotkeyManager.onRecordingStopped = { [weak self] in
            Task { @MainActor in
                await self?.stopDictation()
            }
        }

        // Register the configured hotkey
        hotkeyManager.registerHotkey()

        // Load transcription model (non-fatal if no model yet)
        Task {
            await loadModelIfAvailable()
        }

        // Listen for model download notifications so we can reload
        modelReloadObserver = NotificationCenter.default.addObserver(
            forName: .modelDownloaded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                AppLogger.transcription.info("Model download notification received, reloading...")
                await self?.loadModelIfAvailable()
            }
        }

        // Listen for HUD button taps
        hudCancelObserver = NotificationCenter.default.addObserver(
            forName: .hudCancelTapped,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.cancelDictation()
            }
        }

        hudStopObserver = NotificationCenter.default.addObserver(
            forName: .hudStopTapped,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.stopDictation()
            }
        }

        AppLogger.general.info("AppCoordinator setup complete")
    }

    func teardown() {
        hotkeyManager.unregisterHotkey()
        hudController?.hide()
        if let observer = modelReloadObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = hudCancelObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = hudStopObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        AppLogger.general.info("AppCoordinator teardown complete")
    }

    /// Attempts to load a transcription model. Logs but does not throw on failure.
    private func loadModelIfAvailable() async {
        do {
            try await transcriptionEngine.loadModel()
            AppLogger.transcription.info("Transcription model loaded successfully")
        } catch AppError.noModelFound {
            AppLogger.transcription.warning("No transcription model found — user needs to download one from Settings → Dictation")
        } catch {
            AppLogger.transcription.error("Failed to load model: \(error.localizedDescription)")
        }
    }

    // MARK: - Dictation Flow

    /// Cancel dictation entirely — stop recording, discard audio, hide HUD
    func cancelDictation() {
        guard stateStore.currentState == .recording else { return }
        AppLogger.general.info("Dictation cancelled by user")
        audioCaptureService.cancelRecording()
        stateStore.reset()
        hudController?.hide()
    }

    func startDictation() {
        guard stateStore.currentState == .idle else {
            AppLogger.general.warning("Cannot start dictation: not in idle state")
            return
        }

        // Check permissions
        guard permissionCoordinator.microphoneStatus == .granted else {
            AppLogger.permissions.warning("Microphone permission not granted")
            stateStore.setFailure("Microphone access required. Open Settings → Permissions.")
            return
        }

        // Check if model is loaded
        if !transcriptionEngine.isModelLoaded {
            stateStore.setFailure("No transcription model loaded.\nGo to Settings → Dictation → Download a model first.")
            // Also try to load in background for next time
            Task { await loadModelIfAvailable() }
            return
        }

        AppLogger.audio.info("Starting dictation")
        stateStore.startRecording()
        hudController?.show()

        do {
            try audioCaptureService.startRecording()
        } catch {
            AppLogger.audio.error("Failed to start recording: \(error.localizedDescription)")
            stateStore.setFailure("Failed to start recording: \(error.localizedDescription)")
            hudController?.hide()
        }
    }

    func stopDictation() async {
        guard stateStore.currentState == .recording else {
            AppLogger.general.warning("Cannot stop dictation: not recording")
            return
        }

        AppLogger.audio.info("Stopping dictation")
        stateStore.stopRecording()

        do {
            // 1. Stop recording and get audio frames
            let audioFrames = try await audioCaptureService.stopRecording()
            guard !audioFrames.isEmpty else {
                throw AppError.noAudioCaptured
            }

            AppLogger.audio.info("Captured \(audioFrames.count) audio frames")

            // 2. Transcribe
            stateStore.setTranscribing()
            let options = TranscriptionOptions(
                languageCode: settingsManager.language,
                modelPath: settingsManager.modelPath,
                enableTimestamps: false
            )
            let result = try await transcriptionEngine.transcribe(
                audioFrames: audioFrames,
                options: options
            )

            guard !result.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AppError.emptyTranscript
            }

            AppLogger.transcription.info("Transcription complete: \(result.durationMs)ms")

            // 3. Process transcript
            let profile = settingsManager.formattingProfile
            let processedText = transcriptProcessor.process(result.rawText, profile: profile)

            // 4. Get the focused app name before insertion
            let sourceAppName = NSWorkspace.shared.frontmostApplication?.localizedName

            // 5. Insert text
            stateStore.setInserting()
            let insertionMethod = settingsManager.insertionMethod
            try await insertionCoordinator.insert(processedText, method: insertionMethod)

            AppLogger.insertion.info("Text inserted successfully via \(insertionMethod.rawValue)")

            // 6. Save to history
            let record = TranscriptRecord(
                rawText: result.rawText,
                processedText: processedText,
                sourceAppName: sourceAppName,
                durationMs: result.durationMs,
                languageCode: settingsManager.language,
                insertionMethod: insertionMethod,
                status: .success
            )
            try await transcriptRepository.save(record)

            // 7. Show success
            stateStore.setSuccess(processedText)
            AppLogger.general.info("Dictation flow completed successfully")

        } catch {
            AppLogger.general.error("Dictation failed: \(error.localizedDescription)")

            // Try to save the transcript even on insertion failure
            if case AppError.insertionFailed = error {
                // Copy to clipboard as fallback
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(stateStore.lastTranscript ?? "", forType: .string)
            }

            stateStore.setFailure(error.localizedDescription)
        }

        // Hide HUD immediately
        hudController?.hide()
    }
}

// MARK: - Notification for model downloads
extension Notification.Name {
    static let modelDownloaded = Notification.Name("com.openflow.modelDownloaded")
}
