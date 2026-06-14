//
//  TimelineGrouping.swift
//  拾忆
//
//  把记忆数组按「今天 / 昨天 / 本周 / 本月 / yyyy 年 M 月」聚合
//

import Foundation

struct MemoryGroup: Identifiable {
    var id: String { title }
    let title: String
    let items: [Memory]
    /// 用于排序的代表性时间（取该组最新一条）
    let representative: Date
}

enum TimelineGrouping {

    static func group(_ memories: [Memory], now: Date = Date()) -> [MemoryGroup] {
        guard !memories.isEmpty else { return [] }

        let cal = Calendar.current
        var buckets: [String: (rep: Date, items: [Memory])] = [:]

        for memory in memories {
            let key = bucketKey(for: memory.createdAt, now: now, calendar: cal)
            if var existing = buckets[key] {
                existing.items.append(memory)
                if memory.createdAt > existing.rep { existing.rep = memory.createdAt }
                buckets[key] = existing
            } else {
                buckets[key] = (memory.createdAt, [memory])
            }
        }

        return buckets
            .map { MemoryGroup(title: $0.key, items: $0.value.items, representative: $0.value.rep) }
            .sorted { $0.representative > $1.representative }
    }

    private static func bucketKey(for date: Date, now: Date, calendar cal: Calendar) -> String {
        if cal.isDateInToday(date) { return "今天" }
        if cal.isDateInYesterday(date) { return "昨天" }

        // 本周（同一周内）
        if cal.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return "本周"
        }
        // 本月（同年同月）
        if cal.isDate(date, equalTo: now, toGranularity: .month) {
            return "本月"
        }
        // 同年 → "M 月"
        if cal.isDate(date, equalTo: now, toGranularity: .year) {
            let f = DateFormatter()
            f.locale = Locale(identifier: "zh_CN")
            f.dateFormat = "M 月"
            return f.string(from: date)
        }
        // 跨年 → "yyyy 年 M 月"
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy 年 M 月"
        return f.string(from: date)
    }
}
