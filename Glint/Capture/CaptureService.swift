import AppKit
import ScreenCaptureKit

/// 单块显示器的整屏冻结帧
struct DisplayCapture: @unchecked Sendable {
    let image: CGImage          // 整屏像素图
    let frame: CGRect           // 该屏 CG 全局点坐标 frame（左上原点）
    let scale: CGFloat
    let displayID: CGDirectDisplayID
}

enum CaptureError: LocalizedError {
    case noPermission, noDisplay
    var errorDescription: String? {
        switch self {
        case .noPermission: "缺少屏幕录制权限"
        case .noDisplay: "未找到可用显示器"
        }
    }
}

final class CaptureService {
    static var hasPermission: Bool { CGPreflightScreenCaptureAccess() }
    static func requestPermission() { CGRequestScreenCaptureAccess() }

    func captureAllDisplays() async throws -> [DisplayCapture] {
        guard Self.hasPermission else { throw CaptureError.noPermission }
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard !content.displays.isEmpty else { throw CaptureError.noDisplay }

        var captures: [DisplayCapture] = []
        for display in content.displays {
            let scale = Self.scaleFactor(for: display.displayID)
            let config = SCStreamConfiguration()
            config.width = Int(CGFloat(display.width) * scale)
            config.height = Int(CGFloat(display.height) * scale)
            config.showsCursor = false
            config.captureResolution = .best
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter,
                                                                   configuration: config)
            captures.append(DisplayCapture(image: image, frame: display.frame,
                                           scale: scale, displayID: display.displayID))
        }
        return captures
    }

    private static func scaleFactor(for displayID: CGDirectDisplayID) -> CGFloat {
        NSScreen.screens.first {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) == displayID
        }?.backingScaleFactor ?? 2
    }
}
