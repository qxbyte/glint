import Testing
import Foundation
@testable import GlintKit

private func tempDir() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("glint-test-\(UUID().uuidString)")
}
private let png = Data([0x89, 0x50, 0x4E, 0x47])   // 假 PNG 头即可，Store 不校验内容

@Test func addAndReload() throws {
    let dir = tempDir()
    let store = try HistoryStore(directory: dir, limit: 5)
    let item = try store.add(pngData: png, now: Date(timeIntervalSince1970: 1000))
    #expect(store.items == [item])
    #expect(FileManager.default.fileExists(atPath: item.url.path))
    let reloaded = try HistoryStore(directory: dir, limit: 5)
    #expect(reloaded.items.map(\.id) == [item.id])
}

@Test func fifoTrimsOldest() throws {
    let store = try HistoryStore(directory: tempDir(), limit: 2)
    let a = try store.add(pngData: png, now: Date(timeIntervalSince1970: 1))
    let b = try store.add(pngData: png, now: Date(timeIntervalSince1970: 2))
    let c = try store.add(pngData: png, now: Date(timeIntervalSince1970: 3))
    #expect(store.items == [c, b])                       // 新在前
    #expect(!FileManager.default.fileExists(atPath: a.url.path))  // 最旧文件已删
}

@Test func setLimitTrimsImmediately() throws {
    let store = try HistoryStore(directory: tempDir(), limit: 5)
    for i in 1...4 { _ = try store.add(pngData: png, now: Date(timeIntervalSince1970: Double(i))) }
    try store.setLimit(2)
    #expect(store.items.count == 2)
}
