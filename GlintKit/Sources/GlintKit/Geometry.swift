import CoreGraphics

/// 坐标/矩形换算。全项目约定：内部统一 CG 全局坐标（主屏左上原点、y 向下、单位点），
/// 摆窗时经 flipped 转 AppKit 坐标，裁剪时经 cropRect 转像素坐标。
public enum Geometry {
    /// 由拖拽起止点构造规范化矩形
    public static func rect(from a: CGPoint, to b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
               width: abs(a.x - b.x), height: abs(a.y - b.y))
    }

    public static func clamped(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        let r = rect.intersection(bounds)
        return r.isNull ? .zero : r
    }

    /// 平移选区并保持完全落在 bounds 内
    public static func nudged(_ rect: CGRect, dx: CGFloat, dy: CGFloat, within bounds: CGRect) -> CGRect {
        var r = rect.offsetBy(dx: dx, dy: dy)
        r.origin.x = min(max(r.origin.x, bounds.minX), bounds.maxX - r.width)
        r.origin.y = min(max(r.origin.y, bounds.minY), bounds.maxY - r.height)
        return r
    }

    /// CG 左上原点 ↔ AppKit 左下原点全局坐标（对合变换：调两次还原）
    public static func flipped(_ rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: primaryHeight - rect.maxY,
               width: rect.width, height: rect.height)
    }

    /// 全局点选区 → 某显示器内像素裁剪矩形（左上原点，像素）
    public static func cropRect(selection: CGRect, displayFrame: CGRect, scale: CGFloat) -> CGRect {
        let local = clamped(selection, to: displayFrame)
            .offsetBy(dx: -displayFrame.minX, dy: -displayFrame.minY)
        return CGRect(x: local.minX * scale, y: local.minY * scale,
                      width: local.width * scale, height: local.height * scale).integral
    }
}
