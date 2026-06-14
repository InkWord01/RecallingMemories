//
//  WidgetSnapshotPublisher.swift
//  拾忆
//
//  主 App 端 — 监听数据变化、生成 WidgetSnapshot 并写入 App Group
//

import Foundation
import SwiftData
import WidgetKit

@MainActor
enum WidgetSnapshotPublisher {

    /// 从 SwiftData 拉取最新数据，生成快照并写入；写入完成后请求 WidgetCenter 刷新时间线
    static func publish(modelContainer: ModelContainer) {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Memory>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        guard let memories = try? context.fetch(descriptor) else { return }

        let onThisDayMatches = OnThisDayMatcher.match(memories, against: Date())
        let cal = Calendar.current

        let snapshot = WidgetSnapshot(
            totalCount: memories.count,
            latest: memories.first.map(toItem),
            onThisDay: onThisDayMatches.first.map { memory in
                let years = cal.dateComponents([.year], from: memory.createdAt, to: Date()).year ?? 0
                return WidgetSnapshot.Item(
                    id: memory.id,
                    text: memory.text,
                    createdAt: memory.createdAt,
                    locationName: memory.locationName,
                    moodTag: memory.moodTag,
                    yearsAgo: years
                )
            },
            generatedAt: Date()
        )

        WidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func toItem(_ memory: Memory) -> WidgetSnapshot.Item {
        WidgetSnapshot.Item(
            id: memory.id,
            text: memory.text,
            createdAt: memory.createdAt,
            locationName: memory.locationName,
            moodTag: memory.moodTag,
            yearsAgo: nil
        )
    }
}
