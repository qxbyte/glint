import CoreGraphics
import Foundation
import Observation

public enum AnnotationTool: String, CaseIterable, Sendable {
    case rectangle, ellipse, arrow, pencil, highlighter, text, badge, mosaic, blur
}

/// 单条标注。坐标系为「选区内点坐标（左上原点）」。
/// arrow 特例：rect.origin = 起点，rect.size = 终点相对起点的位移（可为负），不做规范化。
public struct Annotation: Identifiable, Sendable {
    public let id: UUID
    public var tool: AnnotationTool
    public var rect: CGRect
    public var points: [CGPoint]
    public var text: String
    public var badgeNumber: Int
    public var colorHex: String
    public var lineWidth: CGFloat

    public init(tool: AnnotationTool, rect: CGRect = .zero, points: [CGPoint] = [],
                text: String = "", badgeNumber: Int = 0,
                colorHex: String = "#FF3B30", lineWidth: CGFloat = 3) {
        self.id = UUID()
        self.tool = tool
        self.rect = rect
        self.points = points
        self.text = text
        self.badgeNumber = badgeNumber
        self.colorHex = colorHex
        self.lineWidth = lineWidth
    }
}

/// 标注图层栈：非破坏性，合成时才栅格化；撤销重做天然支持
@Observable
public final class AnnotationStack {
    public private(set) var items: [Annotation] = []
    private var redoPile: [Annotation] = []

    public init() {}

    public func push(_ a: Annotation) {
        items.append(a)
        redoPile.removeAll()
    }

    public func undo() {
        guard let last = items.popLast() else { return }
        redoPile.append(last)
    }

    public func redo() {
        guard let last = redoPile.popLast() else { return }
        items.append(last)
    }

    public var canUndo: Bool { !items.isEmpty }
    public var canRedo: Bool { !redoPile.isEmpty }
    public var nextBadgeNumber: Int { items.count(where: { $0.tool == .badge }) + 1 }
}
