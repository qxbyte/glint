import CoreGraphics
import Observation
import GlintKit

@MainActor @Observable
final class SelectionModel {
    enum Phase { case picking, adjusting }
    enum SmartMode: CaseIterable { case element, window, fullscreen }

    var phase: Phase = .picking
    var selection: CGRect = .zero
    var cursor: CGPoint = .zero
    var displayBounds: CGRect = .zero
    var dragOrigin: CGPoint?
    var smartMode: SmartMode = .element
    var hoverRect: CGRect?
    var colorPickMode: Bool = false
    var currentHex: String = ""

    // —— 标注状态（Task 12）——
    var activeTool: AnnotationTool?
    var stack = AnnotationStack()
    var draft: Annotation?
    var strokeColorHex = "#FF3B30"
    var strokeWidth: CGFloat = 3
    var editingText: Annotation?

    func cycleMode() {
        let all = SmartMode.allCases
        guard let idx = all.firstIndex(of: smartMode) else { return }
        smartMode = all[(idx + 1) % all.count]
    }

    func beginDrag(at p: CGPoint) { dragOrigin = p }
    func updateDrag(to p: CGPoint) {
        guard let origin = dragOrigin else { return }
        selection = Geometry.clamped(Geometry.rect(from: origin, to: p), to: displayBounds)
    }
    func endDrag() {
        dragOrigin = nil
        if selection.width >= 2 && selection.height >= 2 { phase = .adjusting }
    }
    func nudge(dx: CGFloat, dy: CGFloat) {
        guard phase == .adjusting else { return }
        selection = Geometry.nudged(selection, dx: dx, dy: dy, within: displayBounds)
    }
}
