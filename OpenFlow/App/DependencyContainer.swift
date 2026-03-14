import Foundation

/// Simple dependency injection container that creates and holds service instances
@MainActor
final class DependencyContainer {
    // MARK: - Shared State
    let stateStore = RecordingStateStore()
    let permissionCoordinator = PermissionCoordinator()
    let settingsManager = SettingsManager()

    // MARK: - Services (lazy initialized)
    private(set) lazy var databaseManager: DatabaseManager = {
        do {
            return try DatabaseManager()
        } catch {
            fatalError("Failed to initialize database: \(error.localizedDescription)")
        }
    }()

    private(set) lazy var transcriptRepository: TranscriptRepository = {
        TranscriptRepository(database: databaseManager)
    }()

    private(set) lazy var replacementRepository: ReplacementRepository = {
        ReplacementRepository(database: databaseManager)
    }()

    private(set) lazy var modelManager: ModelManager = {
        ModelManager()
    }()

    private(set) lazy var audioCaptureService: AudioCaptureServiceProtocol = {
        AudioCaptureService()
    }()

    private(set) lazy var transcriptionEngine: TranscriptionEngine = {
        WhisperTranscriptionEngine(modelManager: modelManager)
    }()

    private(set) lazy var transcriptProcessor: TranscriptProcessor = {
        TranscriptProcessorImpl(replacementRepository: replacementRepository)
    }()

    private(set) lazy var hotkeyManager: GlobalHotkeyManager = {
        GlobalHotkeyManager(settingsManager: settingsManager)
    }()

    private(set) lazy var insertionCoordinator: InsertionCoordinator = {
        InsertionCoordinator()
    }()

    // MARK: - Coordinator Factory

    func makeCoordinator() -> AppCoordinator {
        AppCoordinator(
            stateStore: stateStore,
            hotkeyManager: hotkeyManager,
            audioCaptureService: audioCaptureService,
            transcriptionEngine: transcriptionEngine,
            transcriptProcessor: transcriptProcessor,
            insertionCoordinator: insertionCoordinator,
            transcriptRepository: transcriptRepository,
            settingsManager: settingsManager,
            permissionCoordinator: permissionCoordinator
        )
    }
}
