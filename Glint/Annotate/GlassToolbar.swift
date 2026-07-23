import SwiftUI
import GlintKit

enum ExitAction {
    case copy, save, pin, ocr
}

struct GlassToolbar: View {
    let onAction: (ExitAction) -> Void
    let onCancel: () -> Void

    // —— 标注工具组（Task 12）——
    let selectedTool: AnnotationTool?
    let onToolSelect: (AnnotationTool) -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let currentColorHex: String
    let onColor: (String) -> Void
    let onWidth: (CGFloat) -> Void

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 2) {
                // —— 标注工具组 ——
                ForEach([
                    ("rectangle", AnnotationTool.rectangle),
                    ("circle", .ellipse),
                    ("arrow.up.right", .arrow),
                    ("pencil.line", .pencil),
                    ("highlighter", .highlighter),
                    ("textformat", .text),
                    ("1.circle", .badge),
                    ("squareshape.split.3x3", .mosaic),
                    ("drop", .blur)
                ], id: \.1) { symbol, tool in
                    toolButton(symbol, tool.rawValue) { onToolSelect(tool) }
                        .background(
                            selectedTool == tool
                                ? AnyShapeStyle(.selection)
                                : AnyShapeStyle(.clear),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                }
                Divider().frame(height: 18)
                toolButton("arrow.uturn.backward", "撤销 (⌘Z)") { onUndo() }
                toolButton("arrow.uturn.forward", "重做 (⇧⌘Z)") { onRedo() }
                Divider().frame(height: 18)
                // 颜色/线宽二级菜单
                Menu {
                    ForEach(["#FF3B30", "#FF9500", "#FFCC00", "#34C759",
                             "#007AFF", "#AF52DE", "#000000", "#FFFFFF"],
                            id: \.self) { hex in
                        Button(hex) { onColor(hex) }
                    }
                    Divider()
                    ForEach([2, 3, 5, 8], id: \.self) { w in
                        Button("线宽 \(w)") { onWidth(CGFloat(w)) }
                    }
                } label: {
                    Circle()
                        .fill(Color(cgColor: AnnotationRenderer.color(fromHex: currentColorHex)))
                        .frame(width: 14, height: 14)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 28)
                Divider().frame(height: 18)
                toolButton("text.viewfinder", "OCR (O)") { onAction(.ocr) }
                toolButton("pin", "贴图 (P)") { onAction(.pin) }
                Divider().frame(height: 18)
                toolButton("square.and.arrow.down", "保存 (⌘S)") { onAction(.save) }
                toolButton("doc.on.doc", "复制 (Enter)") { onAction(.copy) }
                toolButton("xmark", "取消 (Esc)", role: .cancel) { onCancel() }
            }
            .padding(6)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
    }

    private func toolButton(_ symbol: String, _ help: String,
                            role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            Image(systemName: symbol).frame(width: 28, height: 24)
        }
        .buttonStyle(.borderless)
        .help(help)
    }
}
