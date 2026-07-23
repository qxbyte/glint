import Testing
import CoreGraphics
@testable import GlintKit

@Test func pushUndoRedo() {
    let s = AnnotationStack()
    s.push(Annotation(tool: .rectangle, rect: CGRect(x: 0, y: 0, width: 10, height: 10)))
    s.push(Annotation(tool: .arrow))
    #expect(s.items.count == 2 && s.canUndo)
    s.undo()
    #expect(s.items.count == 1 && s.canRedo)
    s.redo()
    #expect(s.items.count == 2 && !s.canRedo)
}

@Test func pushClearsRedoPile() {
    let s = AnnotationStack()
    s.push(Annotation(tool: .rectangle))
    s.undo()
    s.push(Annotation(tool: .ellipse))
    #expect(!s.canRedo && s.items.count == 1 && s.items[0].tool == .ellipse)
}

@Test func badgeNumberFollowsLiveCount() {
    let s = AnnotationStack()
    #expect(s.nextBadgeNumber == 1)
    s.push(Annotation(tool: .badge, badgeNumber: 1))
    s.push(Annotation(tool: .badge, badgeNumber: 2))
    #expect(s.nextBadgeNumber == 3)
    s.undo()
    #expect(s.nextBadgeNumber == 2)   // 撤销后序号回退
}
