import SwiftUI
import AppKit

@main
struct OpenFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar item
        MenuBarExtra {
            MenuBarView()
                .environment(appDelegate.container.stateStore)
                .environment(appDelegate.container.permissionCoordinator)
        } label: {
            MenuBarLabel(state: appDelegate.container.stateStore.currentState)
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView()
                .environment(appDelegate.container.stateStore)
                .environment(appDelegate.container.permissionCoordinator)
                .environmentObject(appDelegate.container.settingsManager)
        }

        // History window
        Window("Transcript History", id: "history") {
            HistoryView()
                .environment(appDelegate.container.stateStore)
        }
        .defaultSize(width: 700, height: 500)
    }
}

// MARK: - Menu Bar Label

private struct MenuBarLabel: View {
    let state: RecordingState

    private var iconName: String {
        switch state {
        case .recording: return "waveform"
        case .transcribing: return "brain.head.profile"
        case .inserting: return "text.cursor"
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.triangle.fill"
        default: return "waveform.circle.fill"
        }
    }

    private var isSuccess: Bool {
        if case .success = state { return true }
        return false
    }

    var body: some View {
        Label {
            Text("OpenFlow")
        } icon: {
            Image(systemName: iconName)
                .symbolEffect(.variableColor.iterative, isActive: state == .recording)
                .symbolEffect(.bounce, value: isSuccess)
                .contentTransition(.symbolEffect(.replace))
        }
    }
}

// MARK: - App Delegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let container = DependencyContainer()
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.general.info("OpenFlow app launched")

        // Initialize the coordinator
        coordinator = container.makeCoordinator()
        coordinator?.setup()

        // Check onboarding status
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            showOnboarding()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.teardown()
        AppLogger.general.info("OpenFlow app terminating")
    }

    private func showOnboarding() {
        let onboardingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 680),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        onboardingWindow.title = "Welcome to OpenFlow"
        onboardingWindow.center()
        onboardingWindow.contentView = NSHostingView(
            rootView: OnboardingView(
                permissionCoordinator: container.permissionCoordinator,
                onComplete: { [weak onboardingWindow] in
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    onboardingWindow?.close()
                }
            )
        )
        onboardingWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
