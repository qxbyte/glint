// Glint 应用图标生成脚本（扁平风格）
// 用法: swift make-icon.swift <输出.png>
// 1024x1024 母版：炭黑底 + 蓝色斜块 + 青绿渐变卡片 + 白色取景框

import AppKit
import CoreGraphics

let S: CGFloat = 1024
let args = CommandLine.arguments
guard args.count == 2 else { fatalError("用法: swift make-icon.swift out.png") }

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8,
                    bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}
func hex(_ v: UInt32, _ a: CGFloat = 1) -> CGColor {
    rgba(CGFloat((v >> 16) & 0xFF) / 255, CGFloat((v >> 8) & 0xFF) / 255, CGFloat(v & 0xFF) / 255, a)
}

// ── 1. 炭黑 squircle 底（macOS 网格：824pt 居中，圆角 185）──
let iconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let squircle = CGPath(roundedRect: iconRect, cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()

// 近乎纯色的炭黑，只留极轻的上下明暗（保持扁平）
let bgGrad = CGGradient(colorsSpace: space, colors: [
    hex(0x232527), hex(0x1A1B1D),
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bgGrad, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

// ── 2. 蓝色斜块（垫在卡片左后方，参考图式的错层）──
let quad = CGMutablePath()
quad.move(to: CGPoint(x: 240, y: 610))    // 左上
quad.addLine(to: CGPoint(x: 480, y: 688)) // 右上（向右上扬的斜切）
quad.addLine(to: CGPoint(x: 480, y: 348)) // 右下
quad.addLine(to: CGPoint(x: 240, y: 404)) // 左下
quad.closeSubpath()
ctx.addPath(quad)
ctx.setFillColor(hex(0x1D5FB0))
ctx.fillPath()

// ── 3. 青绿渐变圆角卡片（主体）──
let cardRect = CGRect(x: 342, y: 318, width: 420, height: 388)
let cardPath = CGPath(roundedRect: cardRect, cornerWidth: 64, cornerHeight: 64, transform: nil)
ctx.saveGState()
ctx.addPath(cardPath)
ctx.clip()
let cardGrad = CGGradient(colorsSpace: space, colors: [
    hex(0x00F5B8),   // 右上：亮薄荷绿
    hex(0x0BB8C4),   // 左下：青
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(cardGrad,
                       start: CGPoint(x: cardRect.maxX, y: cardRect.maxY),
                       end: CGPoint(x: cardRect.minX, y: cardRect.minY), options: [])
ctx.restoreGState()

// ── 4. 白色取景框（四角括弧，居中于卡片）──
let center = CGPoint(x: cardRect.midX, y: cardRect.midY)
let half: CGFloat = 118       // 取景框半宽
let arm: CGFloat = 78         // 每条括弧臂长
let lw: CGFloat = 30          // 线宽

ctx.setStrokeColor(rgba(1, 1, 1))
ctx.setLineWidth(lw)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)

for (sx, sy) in [(-1.0, 1.0), (1.0, 1.0), (-1.0, -1.0), (1.0, -1.0)] as [(CGFloat, CGFloat)] {
    let corner = CGPoint(x: center.x + sx * half, y: center.y + sy * half)
    ctx.move(to: CGPoint(x: corner.x - sx * arm, y: corner.y))
    ctx.addLine(to: corner)
    ctx.addLine(to: CGPoint(x: corner.x, y: corner.y - sy * arm))
    ctx.strokePath()
}

ctx.restoreGState()   // 结束 squircle clip

// ── 输出 PNG ──
let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: args[1]))
print("written \(args[1])")
