import SwiftUI
import GlintKit

struct MenuContent: View {
    @State private var items: [HistoryItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("截图  (F6)") { SelectionController.shared.begin() }
            Button("贴图（剪贴板）  (F7)") { PinManager.shared.pinFromClipboard() }
            Divider()
            if items.isEmpty {
                Text("暂无历史截图").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("最近截图").font(.caption).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 6)], spacing: 6) {
                    ForEach(items.prefix(9)) { item in
                        HistoryThumb(item: item)
                    }
                }
            }
            Divider()
            Button("解除所有鼠标穿透") { PinManager.shared.disableAllClickThrough() }
            Button("关闭所有贴图") { PinManager.shared.closeAll() }
            SettingsLink { Text("设置…") }
            Button("退出 Glint") { NSApp.terminate(nil) }
        }
        .padding(12)
        .frame(width: 280)
        .onAppear { items = AppDelegate.history.items }
    }
}

private struct HistoryThumb: View {
    let item: HistoryItem

    var body: some View {
        AsyncImage(url: item.url) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: { Color.gray.opacity(0.2) }
        .frame(width: 72, height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contextMenu {
            Button("复制") {
                if let nsImage = NSImage(contentsOf: item.url),
                   let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    ClipboardService.write(image: cgImage)
                }
            }
            Button("贴图") {
                if let nsImage = NSImage(contentsOf: item.url),
                   let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    PinManager.shared.pin(CaptureResult(
                        image: cgImage,
                        pointRect: CGRect(x: 200, y: 200,
                                          width: CGFloat(cgImage.width) / 2, height: CGFloat(cgImage.height) / 2),
                        scale: 2))
                }
            }
            Button("在访达中显示") {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
        }
    }
}
