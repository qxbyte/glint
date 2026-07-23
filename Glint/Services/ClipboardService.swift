import AppKit

enum ClipboardService {
    static func write(image: CGImage) {
        let rep = NSBitmapImageRep(cgImage: image)
        let pb = NSPasteboard.general
        pb.clearContents()
        if let png = rep.representation(using: .png, properties: [:]) {
            pb.setData(png, forType: .png)
        }
        if let tiff = rep.tiffRepresentation {
            pb.setData(tiff, forType: .tiff)
        }
    }

    static func write(text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    static func readImage() -> CGImage? {
        guard let data = NSPasteboard.general.data(forType: .png)
                ?? NSPasteboard.general.data(forType: .tiff),
              let rep = NSBitmapImageRep(data: data) else { return nil }
        return rep.cgImage
    }
}
