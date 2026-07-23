import AppKit
import SwiftUI
import GlintKit

@MainActor
final class SelectionController {
    static let shared = SelectionController()
    var onComplete: ((CaptureResult) -> Void)?

    private var panels: [OverlayPanel] = []
    private var captures: [DisplayCapture] = []
    private var model: SelectionModel?
    private var keyMonitor: Any?

    func begin() {
        guard panels.isEmpty else { return }   // 幂等
        Task {
            do {
                let captures = try await CaptureService().captureAllDisplays()
                self.present(captures)
            } catch {
                NSSound.beep()   // Task 13 换成权限提示卡
                print("截屏失败: \(error.localizedDescription)")
            }
        }
    }

    private func present(_ captures: [DisplayCapture]) {
        self.captures = captures
        let model = SelectionModel()
        self.model = model
        let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.screens.first?.frame.height ?? 800

        for capture in captures {
            let appKitFrame = Geometry.flipped(capture.frame, primaryHeight: primaryHeight)
            let panel = OverlayPanel(contentRect: appKitFrame)
            panel.contentView = NSHostingView(rootView: SelectionRootView(capture: capture, model: model))
            panel.orderFrontRegardless()
            panels.append(panel)
        }
        // 起始屏 = 当前鼠标所在屏
        let mouse = mouseInCG(primaryHeight: primaryHeight)
        model.displayBounds = captures.first { $0.frame.contains(mouse) }?.frame ?? captures.first?.frame ?? .zero
        model.cursor = mouse

        panels.first?.makeKey()
        NSApp.activate(ignoringOtherApps: true)
        NSCursor.crosshair.set()

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            assert(Thread.isMainThread, "keyMonitor closure must run on main thread")
            return (self?.handleKey(event) == true) ? nil : event
        }
    }

    private func mouseInCG(primaryHeight: CGFloat) -> CGPoint {
        let p = NSEvent.mouseLocation   // AppKit 左下原点
        return CGPoint(x: p.x, y: primaryHeight - p.y)
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        guard let model else { return false }
        let step: CGFloat = event.modifierFlags.contains(.shift) ? 10 : 1
        switch event.keyCode {
        case 53: cancel(); return true                       // Esc
        case 36, 76:                                          // Return / Enter
            if model.phase == .adjusting { finishWithSelection() }
            return true
        case 123: model.nudge(dx: -step, dy: 0); return true  // ←
        case 124: model.nudge(dx: step, dy: 0); return true   // →
        case 125: model.nudge(dx: 0, dy: step); return true   // ↓
        case 126: model.nudge(dx: 0, dy: -step); return true  // ↑
        default: return false
        }
    }

    private func finishWithSelection() {
        guard let model, model.selection.width > 0,
              let capture = captures.first(where: { $0.frame.intersects(model.selection) })
        else { cancel(); return }
        let crop = Geometry.cropRect(selection: model.selection,
                                     displayFrame: capture.frame, scale: capture.scale)
        guard let image = capture.image.cropping(to: crop) else { cancel(); return }
        let result = CaptureResult(image: image, pointRect: model.selection, scale: capture.scale)
        teardown()
        if let onComplete { onComplete(result) }
        else { print("选区完成: \(image.width)x\(image.height) px") }
    }

    private func cancel() { teardown() }

    private func teardown() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
        captures.removeAll()
        model = nil
        NSCursor.arrow.set()
    }
}
