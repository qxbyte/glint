import Testing
import CoreGraphics
@testable import GlintKit

@Test func rectFromTwoPointsNormalizes() {
    let r = Geometry.rect(from: CGPoint(x: 100, y: 200), to: CGPoint(x: 40, y: 50))
    #expect(r == CGRect(x: 40, y: 50, width: 60, height: 150))
}

@Test func clampedIntersects() {
    let r = Geometry.clamped(CGRect(x: -10, y: -10, width: 50, height: 50),
                             to: CGRect(x: 0, y: 0, width: 100, height: 100))
    #expect(r == CGRect(x: 0, y: 0, width: 40, height: 40))
}

@Test func nudgeStopsAtBounds() {
    let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
    let r = Geometry.nudged(CGRect(x: 0, y: 0, width: 10, height: 10), dx: -5, dy: 3, within: bounds)
    #expect(r == CGRect(x: 0, y: 3, width: 10, height: 10))
}

@Test func flipIsInvolution() {
    let r = CGRect(x: 10, y: 20, width: 30, height: 40)
    let once = Geometry.flipped(r, primaryHeight: 900)
    #expect(once == CGRect(x: 10, y: 900 - 20 - 40, width: 30, height: 40))
    #expect(Geometry.flipped(once, primaryHeight: 900) == r)
}

@Test func cropRectOnSecondDisplayRetina() {
    // 副屏在主屏右侧：displayFrame (1920,0,1440,900)，scale 2
    let crop = Geometry.cropRect(selection: CGRect(x: 2000, y: 100, width: 200, height: 50),
                                 displayFrame: CGRect(x: 1920, y: 0, width: 1440, height: 900),
                                 scale: 2)
    #expect(crop == CGRect(x: 160, y: 200, width: 400, height: 100))
}

@Test func cropRectClampsToDisplay() {
    let crop = Geometry.cropRect(selection: CGRect(x: -50, y: -50, width: 100, height: 100),
                                 displayFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                                 scale: 1)
    #expect(crop == CGRect(x: 0, y: 0, width: 50, height: 50))
}
