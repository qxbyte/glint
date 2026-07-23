import CoreGraphics

/// 形状类标注 → CGPath。渲染器（栅格化）与交互画布（预览）共用，保证所见即所得。
public enum AnnotationPathBuilder {
    /// text/badge/mosaic/blur 无路径，返回 nil
    public static func path(for a: Annotation) -> CGPath? {
        switch a.tool {
        case .rectangle:
            return CGPath(rect: a.rect.standardized, transform: nil)
        case .ellipse:
            return CGPath(ellipseIn: a.rect.standardized, transform: nil)
        case .arrow:
            // arrow 语义：origin = 起点，origin + size = 终点（size 可为负）
            let from = a.rect.origin
            let to = CGPoint(x: a.rect.origin.x + a.rect.size.width,
                             y: a.rect.origin.y + a.rect.size.height)
            return arrowPath(from: from, to: to, lineWidth: a.lineWidth)
        case .pencil, .highlighter:
            guard a.points.count > 1 else { return nil }
            let p = CGMutablePath()
            p.move(to: a.points[0])
            for pt in a.points.dropFirst() { p.addLine(to: pt) }
            return p
        case .text, .badge, .mosaic, .blur:
            return nil
        }
    }

    public static func arrowPath(from: CGPoint, to: CGPoint, lineWidth: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let angle = atan2(to.y - from.y, to.x - from.x)
        let headLength = max(12, lineWidth * 4)
        let headAngle: CGFloat = .pi / 7
        let shaftEnd = CGPoint(x: to.x - headLength * 0.6 * cos(angle),
                               y: to.y - headLength * 0.6 * sin(angle))
        path.move(to: from)
        path.addLine(to: shaftEnd)
        // 箭头头部：闭合三角，调用方对整条路径再 fill 一次即得实心头
        path.move(to: to)
        path.addLine(to: CGPoint(x: to.x - headLength * cos(angle - headAngle),
                                 y: to.y - headLength * sin(angle - headAngle)))
        path.addLine(to: CGPoint(x: to.x - headLength * cos(angle + headAngle),
                                 y: to.y - headLength * sin(angle + headAngle)))
        path.closeSubpath()
        return path
    }
}
