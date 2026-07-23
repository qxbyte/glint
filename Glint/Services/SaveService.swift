import AppKit

enum SaveService {
    static var saveDirectory: URL {
        if let path = UserDefaults.standard.string(forKey: "savePath"), !path.isEmpty {
            return URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        }
        return FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Glint")
    }

    static func pngData(from image: CGImage) -> Data? {
        NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    }

    @discardableResult
    static func save(image: CGImage) throws -> URL {
        try FileManager.default.createDirectory(at: saveDirectory, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = saveDirectory.appendingPathComponent("Glint-\(formatter.string(from: Date())).png")
        guard let data = pngData(from: image) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url)
        return url
    }
}
