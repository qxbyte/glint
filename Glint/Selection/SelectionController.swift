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
    private var hoverTask: Task<Void, Never>?
    private let windowDetector = WindowDetector()
    private let elementDetector = ElementDetector()

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

        model.smartMode = ElementDetector.trusted ? .element : .window
        hoverTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.updateHover()
                try? await Task.sleep(for: .milliseconds(33))
            }
        }

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
        case 53: dismiss(); return true                       // Esc
        case 36, 76:                                          // Return / Enter
            if model.phase == .adjusting { complete(.copy) }
            return true
        case 49:                                              // Space：循环模式
            model.cycleMode(); return true
        case 8: model.colorPickMode.toggle(); return true      // C：取色模式切换
        case 123: model.nudge(dx: -step, dy: 0); return true  // ←
        case 124: model.nudge(dx: step, dy: 0); return true   // →
        case 125: model.nudge(dx: 0, dy: step); return true   // ↓
        case 126: model.nudge(dx: 0, dy: -step); return true  // ↑
        default: return false
        }
    }

    private func makeResult() -> CaptureResult? {
        guard let model, model.selection.width > 0,
              let capture = captures.first(where: { $0.frame.intersects(model.selection) })
        else { return nil }
        let crop = Geometry.cropRect(selection: model.selection,
                                     displayFrame: capture.frame, scale: capture.scale)
        guard let image = capture.image.cropping(to: crop) else { return nil }
        return CaptureResult(image: image, pointRect: model.selection, scale: capture.scale)
    }

    func complete(_ action: ExitAction) {
        guard let model, model.phase == .adjusting else { return }
        guard let result = makeResult() else { dismiss(); return }
        // 1. 历史先落库
        try? AppDelegate.history.add(pngData: SaveService.pngData(from: result.image))
        // 2. 动作
        switch action {
        case .copy:
            ClipboardService.write(image: result.image)
        case .save:
            do { try SaveService.save(image: result.image) }
            catch {
                ClipboardService.write(image: result.image)   // 保底不丢图
                Self.notify("保存失败，已复制到剪贴板：\(error.localizedDescription)")
            }
        case .pin: print("TODO Task 13: pin")   // Task 13 替换
        case .ocr: print("TODO Task 14: ocr")   // Task 14 替换
        }
        // 3. 如有 onComplete 回调则调用（兼容旧路径）
        if let onComplete { onComplete(result) }
        dismiss()
    }

    @MainActor static func notify(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }

    func dismiss() { teardown() }

    @MainActor private func updateHover() {
        guard let model, model.phase == .picking, model.dragOrigin == nil else { return }
        let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.screens.first?.frame.height ?? 800
        let p = mouseInCG(primaryHeight: primaryHeight)
        model.cursor = p
        switch model.smartMode {
        case .element:
            model.hoverRect = elementDetector.elementRect(at: p) ?? windowDetector.windowRect(at: p)
        case .window:
            model.hoverRect = windowDetector.windowRect(at: p)
        case .fullscreen:
            model.hoverRect = captures.first { $0.frame.contains(p) }?.frame
        }
        if let hover = model.hoverRect {
            model.hoverRect = Geometry.clamped(hover, to: captures.first { $0.frame.intersects(hover) }?.frame ?? hover)
        }
        // 实时采色：取光标下像素的 HEX
        if let capture = captures.first(where: { $0.frame.contains(p) }) {
            let px = CGPoint(x: (p.x - capture.frame.minX) * capture.scale,
                             y: (p.y - capture.frame.minY) * capture.scale)
            if let c = PixelSampler.rgba(in: capture.image, atPixel: px) {
                model.currentHex = PixelSampler.hexString(r: c.r, g: c.g, b: c.b)
            }
        }
    }

    private func teardown() {
        hoverTask?.cancel()
        hoverTask = nil
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
        captures.removeAll()
        model?.currentHex = ""
        model = nil
        NSCursor.arrow.set()
    }
}
