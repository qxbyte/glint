import AppKit

final class WindowDetector {
    private let ownPID = ProcessInfo.processInfo.processIdentifier

    func windowRect(at point: CGPoint) -> CGRect? {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                                    kCGNullWindowID) as? [[String: Any]]
        else { return nil }
        for info in list {   // 已按 z-order 前→后
            guard (info[kCGWindowLayer as String] as? Int) == 0,
                  (info[kCGWindowOwnerPID as String] as? pid_t) != ownPID,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat]
            else { continue }
            let rect = CGRect(x: boundsDict["X"] ?? 0, y: boundsDict["Y"] ?? 0,
                              width: boundsDict["Width"] ?? 0, height: boundsDict["Height"] ?? 0)
            if rect.contains(point) { return rect }
        }
        return nil
    }
}
