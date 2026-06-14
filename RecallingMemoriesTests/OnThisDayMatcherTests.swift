//
//  OnThisDayMatcherTests.swift
//  RecallingMemoriesTests
//

import XCTest
import SwiftData
@testable import RecallingMemories

@MainActor
final class OnThisDayMatcherTests: XCTestCase {

    func testEmptyWhenNoMemories() {
        let result = OnThisDayMatcher.match([], against: .at(2026, 6, 14))
        XCTAssertTrue(result.isEmpty)
    }

    func testSameMonthDayDifferentYearMatches() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "去年", at: .at(2025, 6, 14, hour: 10))
        TestFactory.memory(in: ctx, text: "前年", at: .at(2024, 6, 14, hour: 14))
        TestFactory.memory(in: ctx, text: "今年其它日子", at: .at(2026, 5, 14))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let result = OnThisDayMatcher.match(memories, against: .at(2026, 6, 14))

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(Set(result.map(\.text)), ["去年", "前年"])
    }

    func testTodayItselfNotIncluded() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        // 今天稍早一点的记忆 — 不应被 OnThisDay 命中（按定义只看历史）
        TestFactory.memory(in: ctx, text: "今天 09:00", at: .at(2026, 6, 14, hour: 9))
        TestFactory.memory(in: ctx, text: "去年", at: .at(2025, 6, 14, hour: 10))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let result = OnThisDayMatcher.match(memories, against: .at(2026, 6, 14, hour: 18))

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.text, "去年")
    }

    func testResultsSortedByDateDescending() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "2024", at: .at(2024, 6, 14))
        TestFactory.memory(in: ctx, text: "2025", at: .at(2025, 6, 14))
        TestFactory.memory(in: ctx, text: "2023", at: .at(2023, 6, 14))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let result = OnThisDayMatcher.match(memories, against: .at(2026, 6, 14))

        XCTAssertEqual(result.map(\.text), ["2025", "2024", "2023"])
    }

    func testFebruary29EdgeCase() {
        // 2024 是闰年，2025 不是 — 在 2 月 29 查询，2026/2/28 当作不同日，不应误匹配
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "闰年同日", at: .at(2024, 2, 29, hour: 10))
        TestFactory.memory(in: ctx, text: "非闰年 2/28", at: .at(2025, 2, 28, hour: 10))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let result = OnThisDayMatcher.match(memories, against: .at(2028, 2, 29))

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.text, "闰年同日")
    }

    func testIgnoresFutureMemories() {
        // 防御：未来时间的记忆不应被匹配（不应该出现，但要稳定）
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "未来", at: .at(2030, 6, 14))
        TestFactory.memory(in: ctx, text: "过去", at: .at(2025, 6, 14))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let result = OnThisDayMatcher.match(memories, against: .at(2026, 6, 14))

        XCTAssertEqual(result.map(\.text), ["过去"])
    }
}
