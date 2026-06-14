//
//  WidgetSnapshot.swift
//  拾忆 / RecallingMemoriesWidget
//
//  共享的轻量快照模型 — 主 App 写入，Widget 读取
//

import Foundation

/// Widget 渲染需要的最小数据集（避免 Widget 直接打开 SwiftData store）
struct WidgetSnapshot: Codable, Equatable {
    /// 总记忆条数
    var totalCount: Int
    /// 最近一条
    var latest: Item?
    /// 「那年今日」首条命中
    var onThisDay: Item?
    /// 快照生成时间
    var generatedAt: Date

    struct Item: Codable, Equatable {
        var id: UUID
        var text: String
        var createdAt: Date
        var locationName: String?
        var moodTag: String?
        /// 与今日相隔多少年（仅 onThisDay 用）
        var yearsAgo: Int?
    }

    static let empty = WidgetSnapshot(totalCount: 0, latest: nil, onThisDay: nil, generatedAt: .distantPast)
}

/// Widget 共享 UserDefaults 读写
enum WidgetSnapshotStore {
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WidgetShared.appGroup)
    }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: WidgetShared.DefaultsKey.snapshot)
    }

    static func load() -> WidgetSnapshot {
        guard let defaults,
              let data = defaults.data(forKey: WidgetShared.DefaultsKey.snapshot),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }
}
