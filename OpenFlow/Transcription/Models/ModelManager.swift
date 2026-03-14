import Foundation

/// Manages local whisper model files in Application Support
final class ModelManager {
    struct ModelInfo: Identifiable {
        let id: String
        let name: String
        let url: URL
        let size: Int64

        var formattedSize: String {
            ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
    }

    private let modelsDirectory: URL

    /// URL of the currently selected/active model
    var activeModelURL: URL? {
        let modelName = UserDefaults.standard.string(forKey: "selectedModelName") ?? "ggml-base.en"
        let url = modelsDirectory.appendingPathComponent("\(modelName).bin")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    init() {
        // ~/Library/Application Support/OpenFlow/Models/
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        modelsDirectory = appSupport.appendingPathComponent("OpenFlow/Models", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)

        AppLogger.transcription.info("Models directory: \(self.modelsDirectory.path)")
    }

    /// Lists all available model files
    func availableModels() -> [ModelInfo] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: modelsDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return [] }

        return contents
            .filter { $0.pathExtension == "bin" }
            .compactMap { url -> ModelInfo? in
                let name = url.deletingPathExtension().lastPathComponent
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return ModelInfo(
                    id: name,
                    name: name,
                    url: url,
                    size: Int64(size)
                )
            }
            .sorted { $0.name < $1.name }
    }

    /// Download a model from Hugging Face
    func downloadModel(name: String, progressHandler: @escaping (Double) -> Void) async throws {
        let urlString = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(name).bin"
        guard let url = URL(string: urlString) else {
            throw AppError.modelLoadFailed("Invalid model URL")
        }

        let destinationURL = modelsDirectory.appendingPathComponent("\(name).bin")

        // Check if already downloaded
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            AppLogger.transcription.info("Model \(name) already exists")
            progressHandler(1.0)
            return
        }

        AppLogger.transcription.info("Downloading model: \(name) from \(urlString)")

        let (tempURL, response) = try await URLSession.shared.download(from: url, delegate: nil)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AppError.modelLoadFailed("Failed to download model: HTTP error")
        }

        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        progressHandler(1.0)

        AppLogger.transcription.info("Model \(name) downloaded successfully to \(destinationURL.path)")
    }

    /// Delete a model file
    func deleteModel(name: String) throws {
        let url = modelsDirectory.appendingPathComponent("\(name).bin")
        try FileManager.default.removeItem(at: url)
        AppLogger.transcription.info("Model \(name) deleted")
    }

    /// Available models that can be downloaded
    static let downloadableModels: [(name: String, displayName: String, size: String)] = [
        ("ggml-tiny.en", "Tiny (English)", "~75 MB"),
        ("ggml-tiny", "Tiny (Multilingual)", "~75 MB"),
        ("ggml-base.en", "Base (English)", "~142 MB"),
        ("ggml-base", "Base (Multilingual)", "~142 MB"),
        ("ggml-small.en", "Small (English)", "~466 MB"),
        ("ggml-small", "Small (Multilingual)", "~466 MB"),
    ]
}
