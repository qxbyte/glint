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
            // 悬停高亮（仅 picking 阶段）
            if model.phase == .picking, let hover = model.hoverRect, hover.intersects(capture.frame) {
                let h = local(hover)
                Rectangle()
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .background(Color.accentColor.opacity(0.12))
                    .frame(width: h.width, height: h.height)
                    .offset(x: h.minX, y: h.minY)
                    .allowsHitTesting(false)
            }
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
                // 标注画布（adjusting 阶段）
                if model.phase == .adjusting {
                    AnnotationCanvas(model: model, selectionLocal: sel)
                        .allowsHitTesting(model.activeTool != nil)
                }
                // 玻璃工具条（adjusting 阶段）
                if model.phase == .adjusting {
                    GlassToolbar(
                        onAction: { SelectionController.shared.complete($0) },
                        onCancel: { SelectionController.shared.dismiss() },
                        selectedTool: model.activeTool,
                        onToolSelect: { tool in
                            model.activeTool = (tool == model.activeTool ? nil : tool)
                        },
                        onUndo: { model.stack.undo() },
                        onRedo: { model.stack.redo() },
                        currentColorHex: model.strokeColorHex,
                        onColor: { model.strokeColorHex = $0 },
                        onWidth: { model.strokeWidth = $0 }
                    )
                    .offset(x: sel.minX,
                            y: sel.maxY + 44 < capture.frame.height ? sel.maxY + 8 : sel.maxY - 44)
                }
            }
            // 放大镜（picking 阶段、光标在本屏时显示）
            if model.phase == .picking, capture.frame.contains(model.cursor) {
                let c = local(CGRect(origin: model.cursor, size: .zero)).origin
                MagnifierView(capture: capture, cursor: model.cursor, hex: model.currentHex)
                    .offset(x: min(max(0, c.x + 20), capture.frame.width - 150),
                            y: min(max(0, c.y + 20), capture.frame.height - 170))
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
                        if model.dragOrigin == nil { model.displayBounds = capture.frame }
                        if model.dragOrigin == nil { model.beginDrag(at: g) }
                        model.updateDrag(to: g)
                    }
                }
                .onEnded { v in
                    guard model.phase == .picking else { return }
                    // 取色模式：单击复制 HEX 并退出
                    if model.colorPickMode {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(model.currentHex, forType: .string)
                        SelectionController.shared.dismiss()
                        return
                    }
                    let moved = hypot(v.translation.width, v.translation.height)
                    if moved < 3, let hover = model.hoverRect {   // 视为单击：采纳悬停区域
                        model.displayBounds = capture.frame
                        model.selection = Geometry.clamped(hover, to: model.displayBounds)
                        model.dragOrigin = nil
                        model.phase = .adjusting
                    } else {
                        model.endDrag()
                    }
                }
        )
        .ignoresSafeArea()
    }
}
