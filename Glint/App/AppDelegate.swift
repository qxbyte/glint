import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 热键注册在 Task 14，权限引导在 Task 14
        if ProcessInfo.processInfo.environment["GLINT_TEST_CAPTURE"] == "1" {
            Task {
                var lines: [String] = []
                do {
                    let captures = try await CaptureService().captureAllDisplays()
                    for c in captures {
                        lines.append("display \(c.displayID): \(c.image.width)x\(c.image.height) px, frame=\(c.frame), scale=\(c.scale)")
                    }
                } catch { lines.append("截屏失败: \(error.localizedDescription)") }
                try? lines.joined(separator: "\n")
                    .write(toFile: "/tmp/glint-capture-test.txt", atomically: true, encoding: .utf8)
            }
        }
    }
}
