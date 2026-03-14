import SwiftUI

/// Native macOS settings with TabView — adopts Liquid Glass automatically
struct SettingsView: View {
    @Environment(RecordingStateStore.self) private var stateStore
    @Environment(PermissionCoordinator.self) private var permissions
    @EnvironmentObject private var settingsManager: SettingsManager

    var body: some View {
        TabView {
            GeneralSettingsView()
                .environmentObject(settingsManager)
                .tabItem {
                    Label("General", systemImage: "gearshape.fill")
                }

            DictationSettingsView()
                .environmentObject(settingsManager)
                .tabItem {
                    Label("Dictation", systemImage: "waveform")
                }

            InsertionSettingsView()
                .environmentObject(settingsManager)
                .tabItem {
                    Label("Insertion", systemImage: "text.cursor")
                }

            ReplacementsSettingsView()
                .tabItem {
                    Label("Replacements", systemImage: "arrow.left.arrow.right")
                }

            PermissionsSettingsView()
                .environment(permissions)
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield.fill")
                }
        }
        .frame(minWidth: 520, minHeight: 440)
    }

    static func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
