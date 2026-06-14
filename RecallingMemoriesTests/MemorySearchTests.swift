//
//  MemorySearchTests.swift
//  RecallingMemoriesTests
//

import XCTest
import SwiftData
@testable import RecallingMemories

@MainActor
final class MemorySearchTests: XCTestCase {

    // MARK: - 空查询

    func testEmptyQueryReturnsAllUntouched() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "A", at: .at(2026, 6, 1))
        TestFactory.memory(in: ctx, text: "B", at: .at(2026, 6, 2))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let result = MemorySearch.filter(memories, by: MemorySearchQuery())

        XCTAssertEqual(result.count, 2)
    }

    // MARK: - 关键词

    func testKeywordHitsText() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "灵感来了")
        TestFactory.memory(in: ctx, text: "其它")

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let result = MemorySearch.filter(memories,
                                         by: MemorySearchQuery(keyword: "灵感"))

        XCTAssertEqual(result.map(\.text), ["灵感来了"])
    }

    func testKeywordCaseInsensitive() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "MeetingNotes today")

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let result = MemorySearch.filter(memories,
                                         by: MemorySearchQuery(keyword: "meeting"))

        XCTAssertEqual(result.count, 1)
    }

    func testMultiTokenAllMustMatch() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "灵感 在 星巴克", location: "星巴克国贸店")
        TestFactory.memory(in: ctx, text: "灵感", location: "家")
        TestFactory.memory(in: ctx, text: "随便", location: "星巴克")

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let result = MemorySearch.filter(memories,
                                         by: MemorySearchQuery(keyword: "灵感 星巴克"))

        XCTAssertEqual(result.count, 2) // 两条都同时含「灵感」和「星巴克」
    }

    func testKeywordMatchesAcrossFields() {
        // keyword 命中人物 / 标签 / 地点也算
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        let zhang = TestFactory.person(in: ctx, name: "张三")
        TestFactory.memory(in: ctx, text: "无关文本", people: [zhang])
        TestFactory.memory(in: ctx, text: "其它", location: "广州")

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let result = MemorySearch.filter(memories,
                                         by: MemorySearchQuery(keyword: "张三"))

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].text, "无关文本")
    }

    // MARK: - 评分排序

    func testScoreRankingTextOverLocation() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        // text 命中得 5 分，仅 location 命中得 3 分
        TestFactory.memory(in: ctx, text: "京都很美",
                           at: .at(2026, 1, 1), location: "京都") // 同时命中两处
        TestFactory.memory(in: ctx, text: "无关",
                           at: .at(2026, 6, 1), location: "京都银阁寺") // 仅 location

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let result = MemorySearch.filter(memories,
                                         by: MemorySearchQuery(keyword: "京都"))

        XCTAssertEqual(result.first?.text, "京都很美") // 命中两处分更高
    }

    func testSameScoreOrderedByDateDescending() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "灵感", at: .at(2026, 1, 1))
        TestFactory.memory(in: ctx, text: "灵感", at: .at(2026, 6, 1))
        TestFactory.memory(in: ctx, text: "灵感", at: .at(2026, 3, 1))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let result = MemorySearch.filter(memories,
                                         by: MemorySearchQuery(keyword: "灵感"))

        let dates = result.map(\.createdAt)
        XCTAssertEqual(dates, dates.sorted(by: >))
    }

    // MARK: - 多维筛选

    func testMoodFilter() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "A", mood: "💡顿悟")
        TestFactory.memory(in: ctx, text: "B", mood: "😌平静")

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        var query = MemorySearchQuery()
        query.moodTag = "💡顿悟"
        let result = MemorySearch.filter(memories, by: query)

        XCTAssertEqual(result.map(\.text), ["A"])
    }

    func testLocationFilterIsExactMatch() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "A", location: "星巴克国贸店")
        TestFactory.memory(in: ctx, text: "B", location: "星巴克")

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        var query = MemorySearchQuery()
        query.locationName = "星巴克"
        let result = MemorySearch.filter(memories, by: query)

        // 精确匹配，「星巴克国贸店」不算
        XCTAssertEqual(result.map(\.text), ["B"])
    }

    func testRequireAttachments() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "无附件")
        TestFactory.memory(in: ctx, text: "有附件",
                           attachments: [TestFactory.photoAttachment()])
        // 触发 SwiftData 关系同步，否则 inverse 关系可能延迟可见
        try! ctx.save()

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        var query = MemorySearchQuery()
        query.requireAttachments = true
        let result = MemorySearch.filter(memories, by: query)

        XCTAssertEqual(result.map(\.text), ["有附件"])
    }

    func testDateRangeFilter() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "5 月", at: .at(2026, 5, 15))
        TestFactory.memory(in: ctx, text: "6 月初", at: .at(2026, 6, 5))
        TestFactory.memory(in: ctx, text: "6 月末", at: .at(2026, 6, 28))

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        var query = MemorySearchQuery()
        query.dateRange = .at(2026, 6, 1)...(.at(2026, 6, 30, hour: 23, minute: 59))
        let result = MemorySearch.filter(memories, by: query)

        XCTAssertEqual(Set(result.map(\.text)), ["6 月初", "6 月末"])
    }

    func testPersonsFilterAllMustBePresent() {
        // 「全部命中」语义：query.personIDs 是子集才算
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        let a = TestFactory.person(in: ctx, name: "A")
        let b = TestFactory.person(in: ctx, name: "B")
        let c = TestFactory.person(in: ctx, name: "C")

        TestFactory.memory(in: ctx, text: "AB", people: [a, b])
        TestFactory.memory(in: ctx, text: "BC", people: [b, c])
        TestFactory.memory(in: ctx, text: "ABC", people: [a, b, c])

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        var query = MemorySearchQuery()
        query.personIDs = [a.id, b.id]
        let result = MemorySearch.filter(memories, by: query)

        XCTAssertEqual(Set(result.map(\.text)), ["AB", "ABC"])
    }

    // MARK: - 组合

    func testKeywordAndMoodCombined() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "灵感", mood: "💡顿悟")
        TestFactory.memory(in: ctx, text: "灵感", mood: "😌平静")
        TestFactory.memory(in: ctx, text: "其它", mood: "💡顿悟")

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        var query = MemorySearchQuery(keyword: "灵感")
        query.moodTag = "💡顿悟"
        let result = MemorySearch.filter(memories, by: query)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].text, "灵感")
        XCTAssertEqual(result[0].moodTag, "💡顿悟")
    }
}
