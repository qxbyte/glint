import CoreGraphics

public enum PixelSampler {
    /// point 为图像内像素坐标（左上原点）；越界返回 nil
    public static func rgba(in image: CGImage, atPixel point: CGPoint)
        -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8)? {
        let x = Int(point.x), y = Int(point.y)
        guard x >= 0, y >= 0, x < image.width, y < image.height else { return nil }
        var pixel = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8,
                                  bytesPerRow: 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        // CG 上下文左下原点：平移使目标像素(左上原点坐标 x,y)恰好落在 1x1 画布上
        ctx.draw(image, in: CGRect(x: CGFloat(-x),
                                   y: CGFloat(y) - CGFloat(image.height - 1),
                                   width: CGFloat(image.width),
                                   height: CGFloat(image.height)))
        return (pixel[0], pixel[1], pixel[2], pixel[3])
    }

    public static func hexString(r: UInt8, g: UInt8, b: UInt8) -> String {
        String(format: "#%02X%02X%02X", r, g, b)
    }
}
