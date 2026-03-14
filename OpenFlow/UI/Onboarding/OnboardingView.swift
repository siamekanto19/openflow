import SwiftUI

struct OnboardingView: View {
    let permissionCoordinator: PermissionCoordinator
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var availableModels: [ModelManager.ModelInfo] = []
    @State private var isDownloading = false
    @State private var downloadingModelName: String?
    @State private var downloadError: String?
    @State private var launchAtLogin = false

    private let totalSteps = 5
    private let modelManager = ModelManager()

    private var hasModel: Bool { !availableModels.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.accentColor : Color.primary.opacity(0.08))
                        .frame(height: 3)
                        .animation(.easeInOut(duration: 0.25), value: currentStep)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            // Content
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: microphoneStep
                case 2: accessibilityStep
                case 3: modelStep
                case 4: readyStep
                default: welcomeStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.25), value: currentStep)

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Spacer()

                if currentStep < totalSteps - 1 {
                    Button("Continue") {
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(currentStep == 3 && !hasModel)
                } else {
                    Button("Get Started") {
                        // Apply launch at login preference
                        if launchAtLogin {
                            LaunchAtLoginHelper.setEnabled(true)
                        }
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 20)
            .padding(.top, 8)
        }
        .frame(width: 520, height: 680)
        .onAppear { refreshModels() }
    }

    private func refreshModels() {
        availableModels = modelManager.availableModels()
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Welcome to OpenFlow")
                    .font(.system(size: 24, weight: .semibold))

                Text("A fast, private dictation tool for macOS.\nSpeak naturally and have your words appear anywhere.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 360)
            }

            VStack(alignment: .leading, spacing: 14) {
                FeatureRow(icon: "cpu", color: .blue, title: "100% Local", description: "Transcription happens entirely on your Mac")
                FeatureRow(icon: "keyboard", color: .purple, title: "Global Shortcut", description: "Hold ⌃⌥Space anywhere to start dictating")
                FeatureRow(icon: "bolt.fill", color: .orange, title: "Apple Silicon", description: "Fast transcription powered by whisper.cpp")
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)

            Spacer()
        }
        .padding(24)
    }

    private var microphoneStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: permissionCoordinator.microphoneStatus == .granted ? "checkmark.circle.fill" : "mic.circle.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(permissionCoordinator.microphoneStatus == .granted ? .green : .blue)

            VStack(spacing: 8) {
                Text("Microphone Access")
                    .font(.system(size: 22, weight: .semibold))

                Text("OpenFlow needs microphone access to listen to your voice.\nAudio is processed locally and never leaves your Mac.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 380)
            }

            if permissionCoordinator.microphoneStatus == .granted {
                Label("Access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Button {
                    Task { await permissionCoordinator.requestMicrophonePermission() }
                } label: {
                    Label("Grant Microphone Access", systemImage: "mic.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()
        }
        .padding(24)
    }

    private var accessibilityStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: permissionCoordinator.accessibilityStatus == .granted ? "checkmark.circle.fill" : "hand.raised.circle.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(permissionCoordinator.accessibilityStatus == .granted ? .green : .purple)

            VStack(spacing: 8) {
                Text("Accessibility Access")
                    .font(.system(size: 22, weight: .semibold))

                Text("OpenFlow needs accessibility access to insert transcribed text into other applications.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 380)
            }

            if permissionCoordinator.accessibilityStatus == .granted {
                Label("Access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                VStack(spacing: 8) {
                    Button {
                        permissionCoordinator.requestAccessibilityPermission()
                    } label: {
                        Label("Open Accessibility Settings", systemImage: "gearshape.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.purple)

                    Text("Add OpenFlow in System Settings → Privacy → Accessibility")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(24)
    }

    private var modelStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: hasModel ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(hasModel ? .green : .teal)

            VStack(spacing: 8) {
                Text("Download a Model")
                    .font(.system(size: 22, weight: .semibold))

                Text("A speech recognition model is required to use OpenFlow.\nChoose a model below to download it.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 380)
            }

            if hasModel {
                Label("Model ready — \(availableModels.first?.name ?? "")", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout)
            }

            VStack(spacing: 8) {
                ForEach(ModelManager.downloadableModels, id: \.name) { model in
                    let isInstalled = availableModels.contains(where: { $0.name == model.name })
                    let isThis = isDownloading && downloadingModelName == model.name

                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(model.displayName)
                                .font(.system(size: 13, weight: .medium))
                            Text(model.size)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if isInstalled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if isThis {
                            ProgressView()
                                .controlSize(.small)
                            Text("Downloading…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Download") {
                                downloadModel(name: model.name)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .tint(.teal)
                            .disabled(isDownloading)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isInstalled ? Color.green.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 40)

            if let error = downloadError {
                Label(error, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            if !hasModel {
                Text("You must download at least one model to continue.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Spacer()
        }
        .padding(24)
    }

    private var readyStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("You're all set")
                    .font(.system(size: 22, weight: .semibold))

                Text("OpenFlow lives in your menu bar.\nUse the shortcut to start dictating anywhere.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 360)
            }

            VStack(alignment: .leading, spacing: 12) {
                TipRow(icon: "hand.tap.fill", color: .blue, text: "Hold ⌃⌥Space to record, release to transcribe")
                TipRow(icon: "text.cursor", color: .purple, text: "Text inserts into your currently focused app")
                TipRow(icon: "menubar.rectangle", color: .orange, text: "Check the menu bar icon for status")
                TipRow(icon: "gearshape", color: .gray, text: "Open Settings to customize behavior")
            }
            .padding(.horizontal, 36)
            .padding(.top, 4)

            // Launch at login toggle
            Toggle(isOn: $launchAtLogin) {
                Label {
                    Text("Launch OpenFlow at login")
                        .font(.system(size: 13))
                } icon: {
                    Image(systemName: "power")
                        .foregroundStyle(.green)
                }
            }
            .toggleStyle(.switch)
            .padding(.horizontal, 40)
            .padding(.top, 4)

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Model Download

    private func downloadModel(name: String) {
        isDownloading = true
        downloadingModelName = name
        downloadError = nil

        Task {
            do {
                try await modelManager.downloadModel(name: name) { _ in }
                refreshModels()
                // Auto-select the downloaded model
                if let model = availableModels.first(where: { $0.name == name }) {
                    UserDefaults.standard.set(model.name, forKey: "selectedModelName")
                    UserDefaults.standard.set(model.url.path, forKey: "modelPath")
                    NotificationCenter.default.post(name: .modelDownloaded, object: nil)
                }
            } catch {
                downloadError = error.localizedDescription
            }
            isDownloading = false
            downloadingModelName = nil
        }
    }
}

// MARK: - Components

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TipRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 12))
                .frame(width: 18)
            Text(text)
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
        }
    }
}
