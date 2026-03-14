import SwiftUI

/// Menu bar popover — clean, native macOS feel with colored icons
struct MenuBarView: View {
    @Environment(RecordingStateStore.self) private var stateStore
    @Environment(PermissionCoordinator.self) private var permissions
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            statusSection

            if let transcript = stateStore.lastTranscript {
                Divider()
                transcriptSection(transcript)
            }

            Divider()
            actionsSection
        }
        .frame(width: 280)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.blue)

            Text("OpenFlow")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                Text(stateStore.currentState.statusText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var statusColor: Color {
        switch stateStore.currentState {
        case .idle: return .green
        case .recording: return .red
        case .transcribing, .inserting: return .orange
        case .success: return .green
        case .failure: return .red
        }
    }

    private var statusSection: some View {
        VStack(spacing: 6) {
            if case .recording = stateStore.currentState {
                Text(formatDuration(stateStore.recordingDuration))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if !permissions.allPermissionsGranted {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("Permissions needed")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Fix") {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                    .tint(.orange)
                }
                .padding(.horizontal, 14)
            }

            Text("⌃⌥Space to record")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
    }

    private func transcriptSection(_ transcript: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Last transcript")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(0.3)

            Text(transcript)
                .font(.system(size: 12))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(transcript, forType: .string)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.blue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var actionsSection: some View {
        VStack(spacing: 0) {
            SettingsLink {
                ActionRow(icon: "gearshape", iconColor: .gray, title: "Settings…")
            }
            .buttonStyle(.plain)

            Button {
                openWindow(id: "history")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                ActionRow(icon: "clock", iconColor: .blue, title: "History")
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.horizontal, 10)

            Button {
                NSApp.terminate(nil)
            } label: {
                ActionRow(icon: "power", iconColor: .red, title: "Quit OpenFlow")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Action Row

private struct ActionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(iconColor)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 12.5))
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovering ? Color.primary.opacity(0.06) : .clear)
        )
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
    }
}
