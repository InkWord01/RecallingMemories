//
//  OnThisDayMatcher.swift
//  拾忆
//
//  「那年今日」匹配器 — 找出历史上同月同日的记忆
//

import Foundation

enum OnThisDayMatcher {

    /// 找到与目标日期「同月同日」、且早于目标日期的所有记忆，按时间倒序
    static func match(_ memories: [Memory], against target: Date,
                      calendar: Calendar = .current) -> [Memory] {
        let targetMonth = calendar.component(.month, from: target)
        let targetDay = calendar.component(.day, from: target)
        let targetStart = calendar.startOfDay(for: target)

        return memories
            .filter { memory in
                calendar.component(.month, from: memory.createdAt) == targetMonth
                    && calendar.component(.day, from: memory.createdAt) == targetDay
                    && memory.createdAt < targetStart
            }
            .sorted { $0.createdAt > $1.createdAt }
    }
}
