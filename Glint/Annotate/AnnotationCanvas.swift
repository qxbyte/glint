import SwiftUI
import GlintKit

struct AnnotationCanvas: View {
    @Bindable var model: SelectionModel
    let selectionLocal: CGRect     // 选区在本屏视图中的局部 rect
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        Canvas { ctx, _ in
            for a in model.stack.items + (model.draft.map { [$0] } ?? []) {
                draw(a, in: &ctx)
            }
        }
        .frame(width: selectionLocal.width, height: selectionLocal.height)
        .contentShape(Rectangle())
        .gesture(drawGesture)
        .overlay(alignment: .topLeading) { textEditor }
        // 用 .position 而非 .offset：offset 只平移渲染、命中区仍留在布局原位（曾致
        // 小选区标注手势全部失效）；position 真实移动布局 frame，命中区随视觉走
        .position(x: selectionLocal.midX, y: selectionLocal.midY)
    }

    /// 根坐标系点 → 选区内标注坐标。手势使用具名根坐标系（.offset 视图的 .local
    /// 语义不扣除偏移，曾导致标注整体偏移一个选区原点），此处显式换算。
    private func toCanvas(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x - selectionLocal.minX, y: p.y - selectionLocal.minY)
    }

    private func draw(_ a: Annotation, in ctx: inout GraphicsContext) {
        let color = Color(cgColor: AnnotationRenderer.color(fromHex: a.colorHex))
        switch a.tool {
        case .text:
            ctx.draw(Text(a.text).font(.system(size: a.lineWidth * 6)).foregroundStyle(color),
                     at: CGPoint(x: a.rect.minX, y: a.rect.minY), anchor: .topLeading)
        case .badge:
            let d = max(22, a.lineWidth * 8)
            let rect = CGRect(x: a.rect.minX, y: a.rect.minY, width: d, height: d)
            ctx.fill(Path(ellipseIn: rect), with: .color(color))
            ctx.draw(Text("\(a.badgeNumber)").font(.system(size: d * 0.55, weight: .bold))
                        .foregroundStyle(.white),
                     at: CGPoint(x: rect.midX, y: rect.midY))
        case .mosaic, .blur:
            // 交互预览：画半透明占位框；真实效果在最终渲染
            ctx.fill(Path(a.rect.standardized), with: .color(.gray.opacity(0.5)))
            ctx.stroke(Path(a.rect.standardized), with: .color(.white), lineWidth: 1)
        default:
            guard let cgPath = AnnotationPathBuilder.path(for: a) else { return }
            var style = StrokeStyle(lineWidth: a.lineWidth, lineCap: .round, lineJoin: .round)
            let paint: Color
            if a.tool == .highlighter {
                style.lineWidth *= 4
                paint = color.opacity(0.4)
            } else {
                paint = color
            }
            ctx.stroke(Path(cgPath), with: .color(paint), style: style)
            if a.tool == .arrow { ctx.fill(Path(cgPath), with: .color(color)) }
        }
    }

    private var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(SelectionRootView.rootSpace))
            .onChanged { v in
                guard let tool = model.activeTool else { return }
                let start = toCanvas(v.startLocation)
                let loc = toCanvas(v.location)
                switch tool {
                case .pencil, .highlighter:
                    if model.draft == nil {
                        model.draft = Annotation(tool: tool, points: [start],
                                                 colorHex: model.strokeColorHex, lineWidth: model.strokeWidth)
                    }
                    model.draft?.points.append(loc)
                case .text, .badge:
                    break   // 点击型，onEnded 处理
                default:
                    var a = model.draft ?? Annotation(tool: tool, colorHex: model.strokeColorHex,
                                                      lineWidth: model.strokeWidth)
                    a.rect = tool == .arrow
                        ? CGRect(origin: start,
                                 size: CGSize(width: loc.x - start.x,
                                              height: loc.y - start.y))
                        : Geometry.rect(from: start, to: loc)
                    model.draft = a
                }
            }
            .onEnded { v in
                guard let tool = model.activeTool else { return }
                let loc = toCanvas(v.location)
                switch tool {
                case .text:
                    let a = Annotation(tool: .text, rect: CGRect(origin: loc, size: .zero),
                                       colorHex: model.strokeColorHex, lineWidth: model.strokeWidth)
                    model.editingText = a
                case .badge:
                    let a = Annotation(tool: .badge, rect: CGRect(origin: loc, size: .zero),
                                       badgeNumber: model.stack.nextBadgeNumber,
                                       colorHex: model.strokeColorHex, lineWidth: model.strokeWidth)
                    model.stack.push(a)
                default:
                    if let draft = model.draft { model.stack.push(draft) }
                    model.draft = nil
                }
            }
    }

    @ViewBuilder private var textEditor: some View {
        if let editing = model.editingText {
            TextField("输入文字", text: Binding(
                get: { model.editingText?.text ?? "" },
                set: { model.editingText?.text = $0 }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: editing.lineWidth * 6))
            .foregroundStyle(Color(cgColor: AnnotationRenderer.color(fromHex: editing.colorHex)))
            .frame(minWidth: 80)
            .offset(x: editing.rect.minX, y: editing.rect.minY)
            .focused($textFieldFocused)
            .onAppear { textFieldFocused = true }   // 面板已是 key window，仍需显式抢首响应者
            .onSubmit {
                if let a = model.editingText, !a.text.isEmpty { model.stack.push(a) }
                model.editingText = nil
                textFieldFocused = false
            }
        }
    }
}
