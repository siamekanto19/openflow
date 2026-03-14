import SwiftUI
import AppKit

/// Floating HUD window controller — shows a minimal overlay during dictation
@MainActor
final class FloatingHUDController {
    private var window: NSPanel?
    private let stateStore: RecordingStateStore

    init(stateStore: RecordingStateStore) {
        self.stateStore = stateStore
    }

    func show() {
        if window == nil {
            createWindow()
        }
        guard let window = window else { return }

        // Start small and slightly above
        window.alphaValue = 0
        let origin = window.frame.origin
        window.setFrameOrigin(NSPoint(x: origin.x, y: origin.y + 8))
        window.contentView?.layer?.setAffineTransform(CGAffineTransform(scaleX: 0.95, y: 0.95))
        window.orderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            context.allowsImplicitAnimation = true
            window.animator().alphaValue = 1
            window.animator().setFrameOrigin(NSPoint(x: origin.x, y: origin.y))
            window.contentView?.layer?.setAffineTransform(.identity)
        }
        AppLogger.ui.info("HUD shown")
    }

    func hide() {
        guard let window = window else { return }
        let origin = window.frame.origin

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            context.allowsImplicitAnimation = true
            window.animator().alphaValue = 0
            window.animator().setFrameOrigin(NSPoint(x: origin.x, y: origin.y + 8))
            window.contentView?.layer?.setAffineTransform(CGAffineTransform(scaleX: 0.95, y: 0.95))
        }, completionHandler: {
            self.window?.orderOut(nil)
            // Reset transform for next show
            self.window?.contentView?.layer?.setAffineTransform(.identity)
        })
        AppLogger.ui.info("HUD hidden")
    }

    private func createWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 42),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 100
            let y = screenFrame.maxY - 80
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let hostingView = NSHostingView(
            rootView: HUDContentView()
                .environment(stateStore)
        )
        hostingView.wantsLayer = true
        panel.contentView = hostingView

        self.window = panel
    }
}

// MARK: - HUD Content

struct HUDContentView: View {
    @Environment(RecordingStateStore.self) private var stateStore

    private let barCount = 5

    private var isListening: Bool {
        switch stateStore.currentState {
        case .recording, .transcribing, .inserting:
            return true
        default:
            return false
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Cancel button (X) — cancels entire session
            Button {
                NotificationCenter.default.post(name: .hudCancelTapped, object: nil)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.white.opacity(0.15)))
            }
            .buttonStyle(.plain)

            // Wave bars
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    WaveBar(index: index, isActive: isListening)
                }
            }
            .frame(width: 30, height: 18)

            // Stop button — stops recording and triggers transcription
            Button {
                NotificationCenter.default.post(name: .hudStopTapped, object: nil)
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.red))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(.black.opacity(0.75))
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
                .shadow(color: .blue.opacity(isListening ? 0.12 : 0), radius: 24, y: 0)
        }
        .animation(.easeInOut(duration: 0.3), value: isListening)
    }
}

// MARK: - HUD Notifications

extension Notification.Name {
    static let hudCancelTapped = Notification.Name("com.openflow.hudCancelTapped")
    static let hudStopTapped = Notification.Name("com.openflow.hudStopTapped")
}

// MARK: - Wave Bar

struct WaveBar: View {
    let index: Int
    let isActive: Bool

    @State private var amplitude: CGFloat = 0.3

    private let minHeight: CGFloat = 0.15
    private let maxHeight: CGFloat = 1.0

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(
                LinearGradient(
                    colors: isActive
                        ? [Color(hue: 0.55, saturation: 0.7, brightness: 1.0),
                           Color(hue: 0.72, saturation: 0.6, brightness: 1.0)]
                        : [.white.opacity(0.3), .white.opacity(0.2)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 3.5, height: isActive ? 18 * amplitude : 18 * minHeight)
            .animation(
                isActive
                    ? .easeInOut(duration: randomDuration)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.08)
                    : .easeOut(duration: 0.3),
                value: isActive
            )
            .onChange(of: isActive) { _, active in
                if active {
                    startAnimating()
                } else {
                    amplitude = minHeight
                }
            }
            .onAppear {
                if isActive {
                    startAnimating()
                }
            }
    }

    private var randomDuration: Double {
        let base = 0.4
        let variation = Double(index) * 0.08
        return base + variation
    }

    private func startAnimating() {
        let targets: [CGFloat] = [0.6, 0.9, 0.5, 0.85, 0.7]
        amplitude = targets[index % targets.count]

        Timer.scheduledTimer(withTimeInterval: randomDuration, repeats: true) { timer in
            if !isActive {
                timer.invalidate()
                return
            }
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: randomDuration)) {
                    amplitude = CGFloat.random(in: 0.3...maxHeight)
                }
            }
        }
    }
}
