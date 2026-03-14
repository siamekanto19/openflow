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
    private var onboardingWindow: NSWindow?

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
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 680),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to OpenFlow"
        window.center()
        window.contentView = NSHostingView(
            rootView: OnboardingView(
                permissionCoordinator: container.permissionCoordinator,
                onComplete: { [weak self] in
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    self?.onboardingWindow?.close()
                    self?.onboardingWindow = nil
                    // App continues running — MenuBarExtra keeps it alive
                }
            )
        )
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Retain the window so it doesn't get deallocated
        self.onboardingWindow = window
    }
}
