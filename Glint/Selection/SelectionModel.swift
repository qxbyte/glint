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

    func cycleMode() {
        let all = SmartMode.allCases
        smartMode = all[(all.firstIndex(of: smartMode)! + 1) % all.count]
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
