import SwiftUI

struct MenuContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Glint").font(.headline)
            Button("测试截屏") {
                Task {
                    do {
                        let captures = try await CaptureService().captureAllDisplays()
                        for c in captures {
                            print("display \(c.displayID): \(c.image.width)x\(c.image.height) px, frame=\(c.frame), scale=\(c.scale)")
                        }
                    } catch { print("截屏失败: \(error.localizedDescription)") }
                }
            }
            Divider()
            Button("退出 Glint") { NSApp.terminate(nil) }
        }
        .padding(12)
        .frame(width: 260)
    }
}
