import SwiftUI

struct MenuContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Glint").font(.headline)
            Button("截图") { SelectionController.shared.begin() }
            Divider()
            Button("贴图（剪贴板）") { PinManager.shared.pinFromClipboard() }
            Button("解除所有鼠标穿透") { PinManager.shared.disableAllClickThrough() }
            Button("关闭所有贴图") { PinManager.shared.closeAll() }
            Divider()
            Button("退出 Glint") { NSApp.terminate(nil) }
        }
        .padding(12)
        .frame(width: 260)
    }
}
