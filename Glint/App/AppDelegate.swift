import AppKit
import SwiftUI
import GlintKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let capture = Self("capture", default: .init(.f6))
    static let pinClipboard = Self("pinClipboard", default: .init(.f7))
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static var history: HistoryStore!
    var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Glint/History")
        let limit = UserDefaults.standard.object(forKey: "historyLimit") as? Int ?? 20
        Self.history = try! HistoryStore(directory: dir, limit: limit)

        // 热键注册
        KeyboardShortcuts.onKeyUp(for: .capture) { Task { @MainActor in SelectionController.shared.begin() } }
        KeyboardShortcuts.onKeyUp(for: .pinClipboard) { Task { @MainActor in PinManager.shared.pinFromClipboard() } }

        // 权限引导
        if !PermissionCenter.screenGranted {
            showOnboarding()
        }

        if ProcessInfo.processInfo.environment["GLINT_TEST_CAPTURE"] == "1" {
            Task {
                var lines: [String] = []
                do {
                    let captures = try await CaptureService().captureAllDisplays()
                    for c in captures {
                        lines.append("display \(c.displayID): \(c.image.width)x\(c.image.height) px, frame=\(c.frame), scale=\(c.scale)")
                    }
                } catch { lines.append("截屏失败: \(error.localizedDescription)") }
                try? lines.joined(separator: "\n")
                    .write(toFile: "/tmp/glint-capture-test.txt", atomically: true, encoding: .utf8)
            }
        }
    }

    func showOnboarding() {
        let window = NSWindow(contentViewController: NSHostingController(rootView: OnboardingView()))
        window.title = "Glint 权限设置"
        window.styleMask = [.titled, .closable]
        window.center()
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }

    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) == onboardingWindow {
            onboardingWindow = nil
        }
    }
}
