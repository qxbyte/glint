import SwiftUI
import GlintKit

struct MagnifierView: View {
    let capture: DisplayCapture
    let cursor: CGPoint          // CG 全局点坐标
    let hex: String

    private let zoom: CGFloat = 8
    private let side: CGFloat = 120

    var body: some View {
        let localPt = CGPoint(x: (cursor.x - capture.frame.minX) * capture.scale,
                              y: (cursor.y - capture.frame.minY) * capture.scale)
        VStack(spacing: 4) {
            Image(decorative: capture.image, scale: 1)
                .interpolation(.none)
                .scaleEffect(zoom, anchor: .topLeading)
                .offset(x: -localPt.x * zoom + side / 2, y: -localPt.y * zoom + side / 2)
                // topLeading 对齐：默认 center 会把原始尺寸的 Image 居中塞进小框，
                // 图像左上角偏离 (0,0)，上面的 offset 数学随之整体错位
                .frame(width: side, height: side, alignment: .topLeading)
                .clipped()
                .overlay {   // 中心十字
                    Path { p in
                        p.move(to: CGPoint(x: side / 2, y: 0)); p.addLine(to: CGPoint(x: side / 2, y: side))
                        p.move(to: CGPoint(x: 0, y: side / 2)); p.addLine(to: CGPoint(x: side, y: side / 2))
                    }
                    .stroke(.white.opacity(0.8), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text("\(Int(cursor.x)), \(Int(cursor.y))  \(hex)")
                .font(.caption2.monospaced())
        }
        .padding(6)
        .glassEffect(.regular, in: .rect(cornerRadius: 10))
    }
}
