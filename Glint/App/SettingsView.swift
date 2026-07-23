import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @AppStorage("savePath") private var savePath = ""
    @AppStorage("historyLimit") private var historyLimit = 20

    var body: some View {
        Form {
            Section("快捷键") {
                KeyboardShortcuts.Recorder("截图", name: .capture)
                KeyboardShortcuts.Recorder("贴图（剪贴板）", name: .pinClipboard)
            }
            Section("保存") {
                HStack {
                    TextField("保存目录", text: $savePath,
                              prompt: Text("~/Pictures/Glint"))
                    Button("选择…") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        if panel.runModal() == .OK, let url = panel.url { savePath = url.path }
                    }
                }
            }
            Section("历史") {
                Stepper("保留最近 \(historyLimit) 张", value: $historyLimit, in: 5...100, step: 5)
                    .onChange(of: historyLimit) { _, n in try? AppDelegate.history.setLimit(n) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
    }
}
