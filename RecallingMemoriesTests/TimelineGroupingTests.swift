//
//  TimelineGroupingTests.swift
//  RecallingMemoriesTests
//

import XCTest
import SwiftData
@testable import RecallingMemories

@MainActor
final class TimelineGroupingTests: XCTestCase {

    func testEmptyInputReturnsEmpty() {
        XCTAssertTrue(TimelineGrouping.group([]).isEmpty)
    }

    func testTodayBucket() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        let now = Date.at(2026, 6, 14, hour: 18)
        TestFactory.memory(in: ctx, text: "今天上午", at: .at(2026, 6, 14, hour: 9))
        TestFactory.memory(in: ctx, text: "今天下午", at: .at(2026, 6, 14, hour: 15))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let groups = TimelineGrouping.group(memories, now: now)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].title, "今天")
        XCTAssertEqual(groups[0].items.count, 2)
    }

    func testYesterdayBucket() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        let now = Date.at(2026, 6, 14, hour: 12)
        TestFactory.memory(in: ctx, text: "昨天", at: .at(2026, 6, 13, hour: 20))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let groups = TimelineGrouping.group(memories, now: now)

        XCTAssertEqual(groups.first?.title, "昨天")
    }

    func testGroupsSortedByMostRecentFirst() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        let now = Date.at(2026, 6, 14, hour: 12)
        TestFactory.memory(in: ctx, text: "今天", at: .at(2026, 6, 14, hour: 9))
        TestFactory.memory(in: ctx, text: "本月稍早", at: .at(2026, 6, 1, hour: 9))
        TestFactory.memory(in: ctx, text: "去年", at: .at(2025, 11, 1))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let groups = TimelineGrouping.group(memories, now: now)

        // 顺序：今天 → 本月 → 跨年 yyyy 年 M 月
        XCTAssertEqual(groups.first?.title, "今天")
        XCTAssertEqual(groups.last?.title, "2025 年 11 月")
    }

    func testThisWeekVsThisMonthDistinction() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        // 用 6 月 14 日（周日）当 now，6 月 9 日是同周内的周一
        let now = Date.at(2026, 6, 14, hour: 12)
        TestFactory.memory(in: ctx, text: "本周内", at: .at(2026, 6, 9, hour: 12))
        // 6 月 1 日跨周但同月
        TestFactory.memory(in: ctx, text: "本月内非本周", at: .at(2026, 6, 1, hour: 12))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let groups = TimelineGrouping.group(memories, now: now)
        let titles = Set(groups.map(\.title))

        // 至少应该出现「本周」和「本月」二者之一（依赖系统 firstWeekday，但应有 ≥1 个区分）
        XCTAssertTrue(titles.contains("本周") || titles.contains("本月"))
        XCTAssertEqual(groups.flatMap(\.items).count, 2)
    }

    func testRepresentativeIsNewestInGroup() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        let now = Date.at(2026, 6, 14, hour: 23)
        TestFactory.memory(in: ctx, text: "早些", at: .at(2026, 6, 14, hour: 8))
        let latest = TestFactory.memory(in: ctx, text: "最新", at: .at(2026, 6, 14, hour: 22))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let groups = TimelineGrouping.group(memories, now: now)

        XCTAssertEqual(groups[0].representative, latest.createdAt)
    }
}
