import SwiftUI

struct OnboardingView: View {
    @State private var screenOK = PermissionCenter.screenGranted
    @State private var axOK = PermissionCenter.axGranted
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Text("欢迎使用 Glint").font(.title2.bold())
            permissionCard(title: "屏幕录制（必需）", granted: screenOK,
                           detail: "用于捕获屏幕画面") {
                CaptureService.requestPermission()
                PermissionCenter.openScreenSettings()
            }
            permissionCard(title: "辅助功能（可选）", granted: axOK,
                           detail: "用于智能识别按钮、面板等 UI 元素；不开启则退化为窗口级选区") {
                ElementDetector.promptForTrust()
                PermissionCenter.openAXSettings()
            }
            Text("授权后需重新启动 Glint 生效").font(.caption).foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 420)
        .onReceive(timer) { _ in
            screenOK = PermissionCenter.screenGranted
            axOK = PermissionCenter.axGranted
        }
    }

    private func permissionCard(title: String, granted: Bool, detail: String,
                                action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(granted ? .green : .secondary)
                .font(.title2)
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !granted { Button("去授权", action: action) }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
}
