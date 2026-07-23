import Testing
import CoreGraphics
@testable import GlintKit

/// 造一张 2x1 图：左像素纯红，右像素纯蓝
private func makeTestImage() -> CGImage {
    let ctx = CGContext(data: nil, width: 2, height: 1, bitsPerComponent: 8, bytesPerRow: 8,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1))
    ctx.fill(CGRect(x: 1, y: 0, width: 1, height: 1))
    return ctx.makeImage()!
}

@Test func samplesCorrectPixels() {
    let img = makeTestImage()
    let left = PixelSampler.rgba(in: img, atPixel: CGPoint(x: 0, y: 0))
    let right = PixelSampler.rgba(in: img, atPixel: CGPoint(x: 1, y: 0))
    #expect(left?.r == 255 && left?.b == 0)
    #expect(right?.r == 0 && right?.b == 255)
}

@Test func outOfBoundsReturnsNil() {
    #expect(PixelSampler.rgba(in: makeTestImage(), atPixel: CGPoint(x: 2, y: 0)) == nil)
}

@Test func hexFormat() {
    #expect(PixelSampler.hexString(r: 255, g: 59, b: 48) == "#FF3B30")
}
