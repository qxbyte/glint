import SwiftUI

enum ExitAction {
    case copy, save, pin, ocr
}

struct GlassToolbar: View {
    let onAction: (ExitAction) -> Void
    let onCancel: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 2) {
                // —— 标注工具组：Task 12 在此插入 ——
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
