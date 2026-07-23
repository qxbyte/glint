import CoreGraphics
import CoreImage
import CoreText
import Foundation

/// 把标注图层栈栅格化到选区图上。
/// 标注坐标系：选区内点坐标（左上原点，y 向下）；base 为像素图，scale = 像素/点。
public enum AnnotationRenderer {
    public static func color(fromHex hex: String) -> CGColor {
        var value: UInt64 = 0
        Scanner(string: String(hex.dropFirst())).scanHexInt64(&value)
        return CGColor(srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
                       green: CGFloat((value >> 8) & 0xFF) / 255,
                       blue: CGFloat(value & 0xFF) / 255, alpha: 1)
    }

    public static func render(base: CGImage, annotations: [Annotation], scale: CGFloat) -> CGImage {
        let w = base.width, h = base.height
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return base }
        ctx.draw(base, in: CGRect(x: 0, y: 0, width: w, height: h))

        for a in annotations {
            switch a.tool {
            case .mosaic, .blur:
                // 基于当前已合成结果做滤镜，再整图回绘（ctx 无残留变换，像素 1:1）
                guard let snapshot = ctx.makeImage() else { continue }
                let filtered = Self.filtered(snapshot, annotation: a, scale: scale)
                ctx.draw(filtered, in: CGRect(x: 0, y: 0, width: w, height: h))
            default:
                // 统一切到「左上原点、点坐标」再画矢量标注
                ctx.saveGState()
                ctx.translateBy(x: 0, y: CGFloat(h))
                ctx.scaleBy(x: scale, y: -scale)
                switch a.tool {
                case .text: Self.drawText(a, in: ctx)
                case .badge: Self.drawBadge(a, in: ctx)
                default: Self.strokeShape(a, in: ctx)
                }
                ctx.restoreGState()
            }
        }
        return ctx.makeImage() ?? base
    }

    private static func strokeShape(_ a: Annotation, in ctx: CGContext) {
        guard let path = AnnotationPathBuilder.path(for: a) else { return }
        ctx.addPath(path)
        ctx.setStrokeColor(color(fromHex: a.colorHex))
        ctx.setLineWidth(a.lineWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        if a.tool == .highlighter {
            ctx.setAlpha(0.4)
            ctx.setLineWidth(a.lineWidth * 4)
        }
        ctx.strokePath()
        if a.tool == .arrow {   // 头部实心
            ctx.addPath(path)
            ctx.setFillColor(color(fromHex: a.colorHex))
            ctx.fillPath()
        }
    }

    private static func filtered(_ image: CGImage, annotation a: Annotation, scale: CGFloat) -> CGImage {
        let ci = CIImage(cgImage: image)
        let output: CIImage
        switch a.tool {
        case .mosaic:
            let f = CIFilter(name: "CIPixellate")!
            f.setValue(ci, forKey: kCIInputImageKey)
            f.setValue(max(8, a.lineWidth * 4) * scale, forKey: kCIInputScaleKey)
            output = f.outputImage!.cropped(to: ci.extent)
        case .blur:
            let f = CIFilter(name: "CIGaussianBlur")!
            f.setValue(ci.clampedToExtent(), forKey: kCIInputImageKey)
            f.setValue(10 * scale, forKey: kCIInputRadiusKey)
            output = f.outputImage!.cropped(to: ci.extent)
        default:
            return image
        }
        // 只取标注 rect 区域贴回原图（CIImage 左下原点，需翻转 y）
        let r = a.rect.standardized
        let pixelRect = CGRect(x: r.minX * scale,
                               y: CGFloat(image.height) - r.maxY * scale,
                               width: r.width * scale, height: r.height * scale)
        let composed = output.cropped(to: pixelRect).composited(over: ci)
        let cictx = CIContext()
        return cictx.createCGImage(composed, from: ci.extent) ?? image
    }

    private static func drawText(_ a: Annotation, in ctx: CGContext) {
        guard !a.text.isEmpty else { return }
        let fontSize = a.lineWidth * 6
        let font = CTFontCreateWithName("PingFang SC" as CFString, fontSize, nil)
        let attr = NSAttributedString(string: a.text, attributes: [
            kCTFontAttributeName as NSAttributedString.Key: font,
            kCTForegroundColorAttributeName as NSAttributedString.Key: color(fromHex: a.colorHex),
        ])
        let line = CTLineCreateWithAttributedString(attr)
        ctx.saveGState()
        // 当前 ctx 左上原点 y 向下；CoreText 需要 y 向上
        ctx.translateBy(x: a.rect.minX, y: a.rect.minY + fontSize)
        ctx.scaleBy(x: 1, y: -1)
        ctx.textPosition = .zero
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }

    private static func drawBadge(_ a: Annotation, in ctx: CGContext) {
        let d = max(22, a.lineWidth * 8)
        let circle = CGRect(x: a.rect.minX, y: a.rect.minY, width: d, height: d)
        ctx.setFillColor(color(fromHex: a.colorHex))
        ctx.fillEllipse(in: circle)
        let font = CTFontCreateWithName("PingFang SC" as CFString, d * 0.55, nil)
        let attr = NSAttributedString(string: "\(a.badgeNumber)", attributes: [
            kCTFontAttributeName as NSAttributedString.Key: font,
            kCTForegroundColorAttributeName as NSAttributedString.Key:
                CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1),
        ])
        let line = CTLineCreateWithAttributedString(attr)
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        ctx.saveGState()
        ctx.translateBy(x: circle.midX - bounds.width / 2, y: circle.midY + bounds.height / 2)
        ctx.scaleBy(x: 1, y: -1)
        ctx.textPosition = .zero
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }
}
