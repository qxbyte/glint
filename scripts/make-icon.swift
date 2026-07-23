// Glint 应用图标生成脚本（方向 B：玻璃棱镜）
// 用法: swift make-icon.swift <输出.png>
// 1024x1024 母版：深色玻璃底 + 斜置磨砂玻璃片 + 对角光束折射色散

import AppKit
import CoreGraphics

let S: CGFloat = 1024
let args = CommandLine.arguments
guard args.count == 2 else { fatalError("用法: swift make-icon.swift out.png") }

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8,
                    bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

// ── 1. 内容 squircle（macOS 图标网格：824pt 居中，圆角 185）──
let iconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let squircle = CGPath(roundedRect: iconRect, cornerWidth: 185, cornerHeight: 185, transform: nil)

ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()

// 背景：深靛 → 近黑深蓝 垂直渐变
let bgGrad = CGGradient(colorsSpace: space, colors: [
    rgba(0.24, 0.21, 0.55, 1),   // 顶部靛紫
    rgba(0.06, 0.07, 0.19, 1),   // 底部近黑
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bgGrad, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

// 左上柔光晕
let glowGrad = CGGradient(colorsSpace: space, colors: [
    rgba(1, 1, 1, 0.10), rgba(1, 1, 1, 0),
] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glowGrad, startCenter: CGPoint(x: 340, y: 760), startRadius: 0,
                       endCenter: CGPoint(x: 340, y: 760), endRadius: 520, options: [])

// ── 2. 光束（入射段：右上 → 玻璃片）──
func drawBeam(from: CGPoint, to: CGPoint, width: CGFloat, color: CGColor, glow: CGFloat) {
    ctx.saveGState()
    let angle = atan2(to.y - from.y, to.x - from.x)
    let length = hypot(to.x - from.x, to.y - from.y)
    ctx.translateBy(x: from.x, y: from.y)
    ctx.rotate(by: angle)
    if glow > 0 {
        ctx.setShadow(offset: .zero, blur: glow, color: color)
    }
    let beamRect = CGRect(x: 0, y: -width / 2, width: length, height: width)
    ctx.addPath(CGPath(roundedRect: beamRect, cornerWidth: width / 2, cornerHeight: width / 2, transform: nil))
    ctx.setFillColor(color)
    ctx.fillPath()
    ctx.restoreGState()
}

let beamEntry = CGPoint(x: 800, y: 812)     // 右上入射起点
let paneHit   = CGPoint(x: 560, y: 545)     // 与玻璃片相交点（视觉中心附近）
let beamExit  = CGPoint(x: 402, y: 368)     // 玻璃片出射点

// 入射白光（带辉光，三层叠出光感）
drawBeam(from: beamEntry, to: paneHit, width: 44, color: rgba(1, 1, 1, 0.10), glow: 0)
drawBeam(from: beamEntry, to: paneHit, width: 20, color: rgba(1, 1, 1, 0.55), glow: 26)
drawBeam(from: beamEntry, to: paneHit, width: 8,  color: rgba(1, 1, 1, 0.95), glow: 10)
// 玻璃内部的折射光路（被磨砂盖住后只余隐约一段，制造"穿过玻璃"的物理感）
drawBeam(from: paneHit, to: beamExit, width: 10, color: rgba(1, 1, 1, 0.30), glow: 6)

// ── 3. 出射色散（穿过玻璃片后分光：青 / 白 / 紫 微微散开）──
func spread(_ from: CGPoint, angleDeg: CGFloat, length: CGFloat) -> CGPoint {
    let a = angleDeg * .pi / 180
    return CGPoint(x: from.x + length * cos(a), y: from.y + length * sin(a))
}
let exitAngle: CGFloat = 228   // 大致延续入射方向（左下）
drawBeam(from: beamExit, to: spread(beamExit, angleDeg: exitAngle + 7, length: 340),
         width: 14, color: rgba(0.45, 0.85, 1.0, 0.70), glow: 16)          // 青
drawBeam(from: beamExit, to: spread(beamExit, angleDeg: exitAngle, length: 360),
         width: 12, color: rgba(1, 1, 1, 0.90), glow: 14)                  // 白（主）
drawBeam(from: beamExit, to: spread(beamExit, angleDeg: exitAngle - 7, length: 340),
         width: 14, color: rgba(0.75, 0.50, 1.0, 0.70), glow: 16)          // 紫

// ── 4. 斜置磨砂玻璃片（盖在光束之上制造"透过玻璃"层次）──
ctx.saveGState()
ctx.translateBy(x: 512, y: 512)
ctx.rotate(by: -26 * .pi / 180)
let paneRect = CGRect(x: -200, y: -270, width: 400, height: 540)
let panePath = CGPath(roundedRect: paneRect, cornerWidth: 44, cornerHeight: 44, transform: nil)

// 磨砂填充 + 对角内渐变
ctx.addPath(panePath)
ctx.clip()
let paneGrad = CGGradient(colorsSpace: space, colors: [
    rgba(1, 1, 1, 0.28), rgba(1, 1, 1, 0.10), rgba(1, 1, 1, 0.18),
] as CFArray, locations: [0, 0.55, 1])!
ctx.drawLinearGradient(paneGrad, start: CGPoint(x: -200, y: 270), end: CGPoint(x: 200, y: -270), options: [])
ctx.restoreGState()

// 玻璃片描边（重新建立旋转坐标，因为 clip 已消耗路径）
ctx.saveGState()
ctx.translateBy(x: 512, y: 512)
ctx.rotate(by: -26 * .pi / 180)
ctx.addPath(panePath)
ctx.setStrokeColor(rgba(1, 1, 1, 0.42))
ctx.setLineWidth(5)
ctx.strokePath()
// 上缘高光短线
ctx.setStrokeColor(rgba(1, 1, 1, 0.85))
ctx.setLineWidth(6)
ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: -140, y: 268))
ctx.addLine(to: CGPoint(x: 60, y: 268))
ctx.strokePath()
ctx.restoreGState()

// ── 5. 入射点光星（四芒星）──
func drawStar(at c: CGPoint, radius r: CGFloat, alpha: CGFloat) {
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: r * 0.9, color: rgba(1, 1, 1, alpha))
    let p = CGMutablePath()
    let inner = r * 0.18
    p.move(to: CGPoint(x: c.x, y: c.y + r))
    p.addLine(to: CGPoint(x: c.x + inner, y: c.y + inner))
    p.addLine(to: CGPoint(x: c.x + r, y: c.y))
    p.addLine(to: CGPoint(x: c.x + inner, y: c.y - inner))
    p.addLine(to: CGPoint(x: c.x, y: c.y - r))
    p.addLine(to: CGPoint(x: c.x - inner, y: c.y - inner))
    p.addLine(to: CGPoint(x: c.x - r, y: c.y))
    p.addLine(to: CGPoint(x: c.x - inner, y: c.y + inner))
    p.closeSubpath()
    ctx.addPath(p)
    ctx.setFillColor(rgba(1, 1, 1, alpha))
    ctx.fillPath()
    ctx.restoreGState()
}
drawStar(at: CGPoint(x: 690, y: 680), radius: 54, alpha: 0.95)

ctx.restoreGState()   // 结束 squircle clip

// ── 输出 PNG ──
let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: args[1]))
print("written \(args[1])")
