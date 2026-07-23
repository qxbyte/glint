import Testing
import CoreGraphics
@testable import GlintKit

private func solidWhite(width: Int, height: Int) -> CGImage {
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                        bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    return ctx.makeImage()!
}

@Test func outputKeepsPixelSize() {
    let base = solidWhite(width: 100, height: 60)
    let out = AnnotationRenderer.render(base: base, annotations: [], scale: 2)
    #expect(out.width == 100 && out.height == 60)
}

@Test func rectangleStrokeChangesPixels() {
    let base = solidWhite(width: 100, height: 100)
    let anno = Annotation(tool: .rectangle,
                          rect: CGRect(x: 10, y: 10, width: 30, height: 20),
                          colorHex: "#FF0000", lineWidth: 3)
    let out = AnnotationRenderer.render(base: base, annotations: [anno], scale: 1)
    // 边框上的点应变红（rect 边缘），中心点仍为白
    let edge = PixelSampler.rgba(in: out, atPixel: CGPoint(x: 10, y: 10))!
    let center = PixelSampler.rgba(in: out, atPixel: CGPoint(x: 25, y: 20))!
    #expect(edge.r == 255 && edge.g < 60)
    #expect(center.r == 255 && center.g == 255 && center.b == 255)
}

@Test func mosaicAltersRegionOnly() {
    // 左半黑右半白的图，对右半白区打马赛克不改变左半
    let ctx = CGContext(data: nil, width: 40, height: 40, bitsPerComponent: 8,
                        bytesPerRow: 160, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: 20, height: 40))
    ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    ctx.fill(CGRect(x: 20, y: 0, width: 20, height: 40))
    let base = ctx.makeImage()!
    let anno = Annotation(tool: .mosaic, rect: CGRect(x: 20, y: 0, width: 20, height: 40))
    let out = AnnotationRenderer.render(base: base, annotations: [anno], scale: 1)
    let leftPixel = PixelSampler.rgba(in: out, atPixel: CGPoint(x: 5, y: 20))!
    #expect(leftPixel.r == 0 && leftPixel.g == 0 && leftPixel.b == 0)
}

@Test func hexColorParses() {
    let c = AnnotationRenderer.color(fromHex: "#FF3B30")
    #expect(abs(c.components![0] - 1.0) < 0.01)
}
