import SwiftUI

@main
struct GlintApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Glint", systemImage: "camera.viewfinder") {
            MenuContent()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
