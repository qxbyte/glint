import SwiftUI

struct PinContentView: View {
    let image: CGImage
    let scale: CGFloat
    weak var panel: PinPanel?
    let onCopy: () -> Void
    let onSave: () -> Void

    @State private var hovering = false

    var body: some View {
        Image(decorative: image, scale: scale)
            .resizable()
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(hovering ? Color.accentColor : .white.opacity(0.4), lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onHover { hovering = $0 }
            .gesture(TapGesture(count: 2).onEnded { panel?.toggleThumbnail() })
            .contextMenu {
                Button("复制") { onCopy() }
                Button("保存") { onSave() }
                Button("鼠标穿透（菜单栏可解除）") { panel?.ignoresMouseEvents = true }
                Divider()
                Button("关闭") { panel?.orderOut(nil) }
            }
    }
}
