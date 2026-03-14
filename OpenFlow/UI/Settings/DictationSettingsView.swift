import SwiftUI

struct DictationSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var availableModels: [ModelManager.ModelInfo] = []
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var downloadError: String?
    @State private var downloadSuccess: String?
    @State private var downloadingModelName: String?

    private let modelManager = ModelManager()

    var body: some View {
        Form {
            Section {
                Picker(selection: $settingsManager.language) {
                    Text("English").tag("en")
                    Text("Spanish").tag("es")
                    Text("French").tag("fr")
                    Text("German").tag("de")
                    Text("Italian").tag("it")
                    Text("Portuguese").tag("pt")
                    Text("Japanese").tag("ja")
                    Text("Korean").tag("ko")
                    Text("Chinese").tag("zh")
                    Text("Auto-detect").tag("auto")
                } label: {
                    Label {
                        Text("Language")
                    } icon: {
                        Image(systemName: "globe")
                            .foregroundStyle(.blue)
                    }
                }
            } header: {
                Text("Language")
            }

            Section {
                if availableModels.isEmpty {
                    Label {
                        Text("No models installed — download one below")
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.orange)
                    }
                } else {
                    ForEach(availableModels) { model in
                        let isActive = model.name == settingsManager.selectedModelName
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(model.name)
                                        .font(.body)
                                    Text(model.formattedSize)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "cpu.fill")
                                    .foregroundStyle(isActive ? .teal : .secondary)
                            }

                            Spacer()

                            if isActive {
                                Text("Active")
                                    .font(.caption)
                                    .foregroundStyle(.teal)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(.teal.opacity(0.12)))
                            } else {
                                Button("Select") {
                                    selectModel(model)
                                }
                                .buttonStyle(.borderless)
                                .foregroundStyle(.blue)
                                .font(.callout)
                            }
                        }
                    }
                }
            } header: {
                Text("Installed Models")
            }

            Section {
                ForEach(ModelManager.downloadableModels, id: \.name) { model in
                    let isInstalled = availableModels.contains(where: { $0.name == model.name })
                    let isThis = isDownloading && downloadingModelName == model.name

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(model.displayName)
                                        .font(.body)
                                    Text(model.size)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundStyle(isInstalled ? .green : .blue)
                            }

                            Spacer()

                            if isInstalled {
                                Text("Installed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else if !isThis {
                                Button("Download") {
                                    downloadModel(name: model.name)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .tint(.blue)
                            }
                        }

                        if isThis {
                            ProgressView(value: downloadProgress)
                                .progressViewStyle(.linear)
                                .tint(.blue)

                            Text("Downloading… \(Int(downloadProgress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let error = downloadError {
                    Label(error, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                }

                if let success = downloadSuccess {
                    Label(success, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.callout)
                }
            } header: {
                Text("Download Models")
            } footer: {
                Text("Larger models are more accurate but use more memory. Models are downloaded from HuggingFace.")
            }
        }
        .formStyle(.grouped)
        .onAppear { refreshModels() }
    }

    private func refreshModels() {
        availableModels = modelManager.availableModels()
    }

    private func selectModel(_ model: ModelManager.ModelInfo) {
        settingsManager.selectedModelName = model.name
        settingsManager.modelPath = model.url.path
        NotificationCenter.default.post(name: .modelDownloaded, object: nil)
    }

    private func downloadModel(name: String) {
        isDownloading = true
        downloadProgress = 0
        downloadError = nil
        downloadSuccess = nil
        downloadingModelName = name

        Task {
            do {
                try await modelManager.downloadModel(name: name) { progress in
                    Task { @MainActor in
                        downloadProgress = progress
                    }
                }
                refreshModels()
                if let model = availableModels.first(where: { $0.name == name }) {
                    settingsManager.selectedModelName = model.name
                    settingsManager.modelPath = model.url.path
                } else if let first = availableModels.first {
                    settingsManager.selectedModelName = first.name
                    settingsManager.modelPath = first.url.path
                }
                NotificationCenter.default.post(name: .modelDownloaded, object: nil)
                downloadSuccess = "Model downloaded and activated."
            } catch {
                downloadError = "Download failed: \(error.localizedDescription)"
            }
            isDownloading = false
            downloadingModelName = nil
        }
    }
}
