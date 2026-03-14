import SwiftUI

/// Menu bar popover — clean, native macOS feel
struct MenuBarView: View {
    @Environment(RecordingStateStore.self) private var stateStore
    @Environment(PermissionCoordinator.self) private var permissions

    var body: some View {
        VStack(spacing: 0) {
            header

            statusSection

            actionsSection
        }
        .frame(width: 260)
        .padding(.vertical, 4)
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
        .padding(.vertical, 8)
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
        VStack(spacing: 4) {
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
        .padding(.vertical, 6)
    }

    private var actionsSection: some View {
        VStack(spacing: 0) {
            // Start / Stop Recording
            if stateStore.currentState == .recording {
                Button {
                    NotificationCenter.default.post(name: .hudStopTapped, object: nil)
                } label: {
                    PopoverRow(icon: "stop.circle.fill", iconColor: .red, title: "Stop Recording")
                }
                .buttonStyle(.plain)
            } else if stateStore.currentState == .idle {
                Button {
                    NotificationCenter.default.post(name: .menuBarStartRecording, object: nil)
                } label: {
                    PopoverRow(icon: "record.circle", iconColor: .red, title: "Start Recording")
                }
                .buttonStyle(.plain)
            }

            SettingsLink {
                PopoverRow(icon: "gearshape.fill", iconColor: .gray, title: "Settings…")
            }
            .buttonStyle(.plain)

            Button {
                NSApp.terminate(nil)
            } label: {
                PopoverRow(icon: "power.circle.fill", iconColor: .red, title: "Quit OpenFlow")
            }
            .buttonStyle(.plain)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Popover Row (edge-to-edge highlight, no rounded corners)

private struct PopoverRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
                .frame(width: 18)

            Text(title)
                .font(.system(size: 13))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(isHovering ? Color.primary.opacity(0.08) : .clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
    }
}
