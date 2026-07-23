import AppKit

final class PinPanel: NSPanel {
    var baseSize: CGSize = .zero          // 点尺寸基准
    var zoomLevel: CGFloat = 1 { didSet { applyZoom() } }
    private var thumbnailMode = false
    private var savedFrame: NSRect?

    init(contentRect: NSRect) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
    }
    override var canBecomeKey: Bool { true }

    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.option) {
            alphaValue = min(1, max(0.15, alphaValue + event.deltaY * 0.03))
        } else {
            zoomLevel = min(5, max(0.2, zoomLevel + event.deltaY * 0.02))
        }
    }

    private func applyZoom() {
        guard baseSize != .zero else { return }
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let size = CGSize(width: baseSize.width * zoomLevel, height: baseSize.height * zoomLevel)
        setFrame(NSRect(x: center.x - size.width / 2, y: center.y - size.height / 2,
                        width: size.width, height: size.height), display: true, animate: false)
    }

    func toggleThumbnail() {
        if thumbnailMode, let saved = savedFrame {
            setFrame(saved, display: true, animate: true)
        } else {
            savedFrame = frame
            let w: CGFloat = 96
            let h = w * frame.height / frame.width
            setFrame(NSRect(x: frame.minX, y: frame.maxY - h, width: w, height: h),
                     display: true, animate: true)
        }
        thumbnailMode.toggle()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { orderOut(nil) }   // Esc 关闭焦点贴图
        else { super.keyDown(with: event) }
    }
}
