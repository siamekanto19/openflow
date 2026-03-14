import SwiftUI

struct InsertionSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager

    var body: some View {
        Form {
            Section {
                Picker(selection: $settingsManager.insertionMethod) {
                    Label {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Clipboard Paste")
                            Text("Uses ⌘V — fast, temporarily modifies clipboard")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "doc.on.clipboard.fill")
                            .foregroundStyle(.blue)
                    }
                    .tag(InsertionMethod.paste)

                    Label {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Simulated Typing")
                            Text("Types each key — slower, preserves clipboard")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "keyboard.fill")
                            .foregroundStyle(.purple)
                    }
                    .tag(InsertionMethod.typing)
                } label: {
                    Label {
                        Text("Method")
                    } icon: {
                        Image(systemName: "text.cursor")
                            .foregroundStyle(.indigo)
                    }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text("Text Insertion")
            }

            Section {
                Picker(selection: $settingsManager.formattingProfile) {
                    ForEach(FormattingProfile.allCases) { profile in
                        Text(profile.displayName).tag(profile)
                    }
                } label: {
                    Label {
                        Text("Profile")
                    } icon: {
                        Image(systemName: "textformat")
                            .foregroundStyle(.orange)
                    }
                }

                Text(settingsManager.formattingProfile.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Formatting")
            }
        }
        .formStyle(.grouped)
    }
}
