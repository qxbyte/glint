import CoreGraphics

/// 跨模块流转的截图结果：Capture 产出，Annotate / Pin / Services 消费
public struct CaptureResult: @unchecked Sendable {
    public let image: CGImage      // 选区像素图
    public let pointRect: CGRect   // CG 全局点坐标选区（主屏左上原点，y 向下）
    public let scale: CGFloat

    public init(image: CGImage, pointRect: CGRect, scale: CGFloat) {
        self.image = image
        self.pointRect = pointRect
        self.scale = scale
    }
}
