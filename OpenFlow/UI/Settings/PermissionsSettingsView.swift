import SwiftUI

struct PermissionsSettingsView: View {
    @Environment(PermissionCoordinator.self) private var permissions

    var body: some View {
        Form {
            Section {
                // Microphone
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Microphone")
                            Text("Capture speech for transcription")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(permissions.microphoneStatus == .granted ? .green : .blue)
                    }

                    Spacer()

                    PermissionBadge(status: permissions.microphoneStatus)

                    if permissions.microphoneStatus != .granted {
                        Button(permissions.microphoneStatus == .unknown ? "Grant" : "Settings") {
                            if permissions.microphoneStatus == .unknown {
                                Task { await permissions.requestMicrophonePermission() }
                            } else {
                                permissions.openMicrophoneSettings()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.blue)
                    }
                }

                // Accessibility
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Accessibility")
                            Text("Insert text into other applications")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(permissions.accessibilityStatus == .granted ? .green : .purple)
                    }

                    Spacer()

                    PermissionBadge(status: permissions.accessibilityStatus)

                    if permissions.accessibilityStatus != .granted {
                        Button("Settings") {
                            permissions.requestAccessibilityPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.purple)
                    }
                }
            } header: {
                Text("Required Permissions")
            } footer: {
                Text("After granting permissions in System Settings, click Refresh below.")
            }

            Section {
                Button("Refresh Permissions") {
                    permissions.checkAllPermissions()
                }
                .buttonStyle(.bordered)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Permission Badge

private struct PermissionBadge: View {
    let status: PermissionCoordinator.PermissionState

    private var statusText: String {
        switch status {
        case .granted: return "Granted"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .unknown: return "Not Set"
        }
    }

    private var statusColor: Color {
        switch status {
        case .granted: return .green
        case .denied: return .red
        case .restricted: return .orange
        case .unknown: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
