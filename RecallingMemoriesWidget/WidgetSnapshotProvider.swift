//
//  WidgetSnapshotProvider.swift
//  RecallingMemoriesWidget
//
//  TimelineProvider — 从 App Group 读取 WidgetSnapshot
//

import WidgetKit
import SwiftUI

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct WidgetSnapshotProvider: TimelineProvider {

    /// 占位（系统 Gallery / 加载状态展示）
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: .preview)
    }

    /// 系统 Gallery 预览 + 立即占位
    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snapshot = context.isPreview ? .preview : WidgetSnapshotStore.load()
        completion(SnapshotEntry(date: Date(), snapshot: snapshot))
    }

    /// Timeline — 拾忆是「事件驱动」型 Widget（主 App 写入即触发刷新）
    /// 这里仍排一条 24h 后的兜底，确保即便主 App 长期未启动也会自然过期重排
    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.load()
        let now = Date()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        let timeline = Timeline(entries: [SnapshotEntry(date: now, snapshot: snapshot)], policy: .after(next))
        completion(timeline)
    }
}

// MARK: - 假数据（系统预览 / Gallery 用）

extension WidgetSnapshot {
    static let preview = WidgetSnapshot(
        totalCount: 128,
        latest: WidgetSnapshot.Item(
            id: UUID(),
            text: "下午阳光很好，想到一个新点子。",
            createdAt: Date().addingTimeInterval(-3600),
            locationName: "星巴克·国贸店",
            moodTag: "💡顿悟",
            yearsAgo: nil
        ),
        onThisDay: WidgetSnapshot.Item(
            id: UUID(),
            text: "去年的此时，雨刚停。",
            createdAt: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(),
            locationName: "西湖·苏堤",
            moodTag: "🌙怅然",
            yearsAgo: 1
        ),
        generatedAt: Date()
    )
}
