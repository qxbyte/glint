import AppKit

enum PermissionCenter {
    static var screenGranted: Bool { CGPreflightScreenCaptureAccess() }
    static var axGranted: Bool { AXIsProcessTrusted() }

    private static let screenSettingsURL = URL(string:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
    private static let axSettingsURL = URL(string:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")

    static func openScreenSettings() {
        guard let url = screenSettingsURL else { return }
        NSWorkspace.shared.open(url)
    }

    static func openAXSettings() {
        guard let url = axSettingsURL else { return }
        NSWorkspace.shared.open(url)
    }
}
