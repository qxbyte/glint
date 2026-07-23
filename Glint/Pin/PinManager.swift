import AppKit
import SwiftUI
import GlintKit

@MainActor
final class PinManager {
    static let shared = PinManager()
    private var panels: [PinPanel] = []
    var count: Int { panels.filter { $0.isVisible }.count }

    func pin(_ result: CaptureResult) {
        let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.screens.first?.frame.height ?? 800
        let appKitFrame = Geometry.flipped(result.pointRect, primaryHeight: primaryHeight)
        makePanel(image: result.image, scale: result.scale, frame: appKitFrame)
    }

    func pinFromClipboard() {
        guard let image = ClipboardService.readImage() else { NSSound.beep(); return }
        let scale: CGFloat = 2
        let size = CGSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale)
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { NSSound.beep(); return }
        let visibleFrame = screen.visibleFrame
        makePanel(image: image, scale: scale,
                  frame: NSRect(x: visibleFrame.midX - size.width / 2,
                                y: visibleFrame.midY - size.height / 2,
                                width: size.width, height: size.height))
    }

    private func makePanel(image: CGImage, scale: CGFloat, frame: NSRect) {
        panels.removeAll { !$0.isVisible }   // 顺手清理已关闭的
        let panel = PinPanel(contentRect: frame)
        panel.baseSize = frame.size
        panel.contentView = NSHostingView(rootView: PinContentView(
            image: image, scale: scale, panel: panel,
            onCopy: { ClipboardService.write(image: image) },
            onSave: { try? SaveService.save(image: image) }
        ))
        panel.orderFrontRegardless()
        panels.append(panel)
    }

    func closeAll() { panels.forEach { $0.orderOut(nil) }; panels.removeAll() }
    func disableAllClickThrough() { panels.forEach { $0.ignoresMouseEvents = false } }
}
