import SwiftUI
import GlintKit

struct SelectionRootView: View {
    let capture: DisplayCapture
    @Bindable var model: SelectionModel

    /// CG 全局点坐标 → 本视图局部坐标（面板恰好铺满该屏，两者仅差一个平移）
    private func local(_ r: CGRect) -> CGRect { r.offsetBy(dx: -capture.frame.minX, dy: -capture.frame.minY) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(decorative: capture.image, scale: capture.scale)
            // 蒙层：全屏黑 40%，选区处挖洞
            Canvas { ctx, size in
                var path = Path(CGRect(origin: .zero, size: size))
                if model.selection.width > 0 { path.addRect(local(model.selection)) }
                ctx.fill(path, with: .color(.black.opacity(0.4)), style: FillStyle(eoFill: true))
            }
            .allowsHitTesting(false)
            // 选区边框 + 尺寸角标
            if model.selection.width > 0 {
                let sel = local(model.selection)
                Rectangle()
                    .strokeBorder(.white, lineWidth: 1)
                    .frame(width: sel.width, height: sel.height)
                    .offset(x: sel.minX, y: sel.minY)
                    .allowsHitTesting(false)
                Text("\(Int(model.selection.width * capture.scale)) × \(Int(model.selection.height * capture.scale)) px")
                    .font(.caption.monospacedDigit())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .glassEffect()
                    .offset(x: sel.minX, y: max(0, sel.minY - 26))
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { v in
                    let g = CGPoint(x: v.location.x + capture.frame.minX,
                                    y: v.location.y + capture.frame.minY)
                    model.cursor = g
                    if model.phase == .picking {
                        if model.dragOrigin == nil { model.beginDrag(at: g) }
                        model.updateDrag(to: g)
                    }
                }
                .onEnded { _ in if model.phase == .picking { model.endDrag() } }
        )
        .ignoresSafeArea()
    }
}
