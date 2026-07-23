import ApplicationServices

final class ElementDetector {
    static var trusted: Bool { AXIsProcessTrusted() }

    static func promptForTrust() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private let systemWide = AXUIElementCreateSystemWide()

    func elementRect(at point: CGPoint) -> CGRect? {
        var element: AXUIElement?
        guard AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y),
                                               &element) == .success,
              let element else { return nil }
        var posValue: CFTypeRef?, sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posValue) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success
        else { return nil }
        var origin = CGPoint.zero, size = CGSize.zero
        AXValueGetValue(posValue as! AXValue, .cgPoint, &origin)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        let rect = CGRect(origin: origin, size: size)
        return rect.isEmpty ? nil : rect
    }
}
