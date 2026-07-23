import SwiftUI

struct MenuContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Glint").font(.headline)
            Button("截图") { SelectionController.shared.begin() }
            Divider()
            Button("退出 Glint") { NSApp.terminate(nil) }
        }
        .padding(12)
        .frame(width: 260)
    }
}
