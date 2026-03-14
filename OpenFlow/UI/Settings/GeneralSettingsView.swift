import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager

    var body: some View {
        Form {
            Section {
                HStack {
                    Label {
                        Text("Global Shortcut")
                    } icon: {
                        Image(systemName: "keyboard.fill")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    HStack(spacing: 3) {
                        KeyCap("⌃")
                        KeyCap("⌥")
                        KeyCap("Space")
                    }
                }

                Picker(selection: $settingsManager.recordingMode) {
                    ForEach(RecordingMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                } label: {
                    Label {
                        Text("Recording Mode")
                    } icon: {
                        Image(systemName: "record.circle")
                            .foregroundStyle(.red)
                    }
                }

                Toggle(isOn: $settingsManager.showHUD) {
                    Label {
                        Text("Show HUD overlay")
                    } icon: {
                        Image(systemName: "rectangle.inset.filled")
                            .foregroundStyle(.indigo)
                    }
                }
            } header: {
                Text("Behavior")
            }

            Section {
                Toggle(isOn: $settingsManager.launchAtLogin) {
                    Label {
                        Text("Launch at Login")
                    } icon: {
                        Image(systemName: "power")
                            .foregroundStyle(.green)
                    }
                }
                .onChange(of: settingsManager.launchAtLogin) { _, newValue in
                    LaunchAtLoginHelper.setEnabled(newValue)
                }
            } header: {
                Text("Startup")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Key Cap

struct KeyCap: View {
    let key: String

    init(_ key: String) {
        self.key = key
    }

    var body: some View {
        Text(key)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
    }
}
