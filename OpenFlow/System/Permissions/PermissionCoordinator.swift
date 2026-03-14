import Foundation
import AVFoundation
import AppKit

/// Manages checking and requesting microphone & accessibility permissions
@Observable
@MainActor
final class PermissionCoordinator {
    enum PermissionState: Equatable {
        case unknown
        case granted
        case denied
        case restricted
    }

    var microphoneStatus: PermissionState = .unknown
    var accessibilityStatus: PermissionState = .unknown

    var allPermissionsGranted: Bool {
        microphoneStatus == .granted && accessibilityStatus == .granted
    }

    init() {
        checkAllPermissions()
    }

    func checkAllPermissions() {
        checkMicrophonePermission()
        checkAccessibilityPermission()
    }

    // MARK: - Microphone

    func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphoneStatus = .granted
            AppLogger.permissions.info("Microphone permission: granted")
        case .denied:
            microphoneStatus = .denied
            AppLogger.permissions.warning("Microphone permission: denied")
        case .restricted:
            microphoneStatus = .restricted
            AppLogger.permissions.warning("Microphone permission: restricted")
        case .notDetermined:
            microphoneStatus = .unknown
            AppLogger.permissions.info("Microphone permission: not determined")
        @unknown default:
            microphoneStatus = .unknown
        }
    }

    func requestMicrophonePermission() async {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        microphoneStatus = granted ? .granted : .denied
        AppLogger.permissions.info("Microphone permission request result: \(granted)")
    }

    // MARK: - Accessibility

    func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        accessibilityStatus = trusted ? .granted : .denied
        AppLogger.permissions.info("Accessibility permission: \(trusted ? "granted" : "denied")")
    }

    func requestAccessibilityPermission() {
        // Open System Settings to the Accessibility pane
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // Re-check after a delay
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            checkAccessibilityPermission()
        }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
}
