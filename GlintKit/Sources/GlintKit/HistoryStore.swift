import Foundation

public struct HistoryItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let url: URL
    public let createdAt: Date
}

/// 截图历史：PNG 落盘 + FIFO 上限。文件名 <毫秒时间戳>-<uuid前8位>.png
public final class HistoryStore {
    public private(set) var items: [HistoryItem] = []
    private let directory: URL
    private var limit: Int

    public init(directory: URL, limit: Int) throws {
        self.directory = directory
        self.limit = max(1, limit)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "png" }
        items = files.compactMap { url in
            let id = url.deletingPathExtension().lastPathComponent
            guard let ms = Double(id.prefix(while: { $0 != "-" })) else { return nil }
            return HistoryItem(id: id, url: url, createdAt: Date(timeIntervalSince1970: ms / 1000))
        }
        .sorted { $0.createdAt > $1.createdAt }
        trim()
    }

    @discardableResult
    public func add(pngData: Data, now: Date = Date()) throws -> HistoryItem {
        let id = "\(Int(now.timeIntervalSince1970 * 1000))-\(UUID().uuidString.prefix(8))"
        let url = directory.appendingPathComponent("\(id).png")
        try pngData.write(to: url)
        let item = HistoryItem(id: id, url: url, createdAt: now)
        items.insert(item, at: 0)
        trim()
        return item
    }

    public func setLimit(_ n: Int) throws {
        limit = max(1, n)
        trim()
    }

    public func remove(_ item: HistoryItem) throws {
        try? FileManager.default.removeItem(at: item.url)
        items.removeAll { $0.id == item.id }
    }

    public func clear() throws {
        for item in items { try? FileManager.default.removeItem(at: item.url) }
        items.removeAll()
    }

    private func trim() {
        while items.count > limit {
            let victim = items.removeLast()
            try? FileManager.default.removeItem(at: victim.url)
        }
    }
}
