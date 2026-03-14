import SwiftUI

struct OnboardingView: View {
    let permissionCoordinator: PermissionCoordinator
    let onComplete: () -> Void

    @State private var currentStep = 0
    private let totalSteps = 4

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
                case 3: readyStep
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
                } else {
                    Button("Get Started") {
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

            if !permissionCoordinator.allPermissionsGranted {
                Label {
                    Text("Some permissions are missing — grant them later in Settings")
                        .font(.caption)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.orange.opacity(0.06))
                )
            }

            Spacer()
        }
        .padding(24)
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
