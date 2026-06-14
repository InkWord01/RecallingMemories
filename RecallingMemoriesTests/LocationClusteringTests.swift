//
//  LocationClusteringTests.swift
//  RecallingMemoriesTests
//

import XCTest
import SwiftData
@testable import RecallingMemories

@MainActor
final class LocationClusteringTests: XCTestCase {

    func testMemoriesWithoutLocationAreSkipped() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "无位置1")
        TestFactory.memory(in: ctx, text: "无位置2")

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        XCTAssertTrue(LocationClustering.cluster(memories).isEmpty)
    }

    func testNearbyCoordinatesMergeIntoOneCluster() {
        // 经纬度差 < 0.0001 ≈ 11m，应聚为一组
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "A", lat: 39.90000, lon: 116.40000, mood: nil)
        TestFactory.memory(in: ctx, text: "B", lat: 39.90003, lon: 116.40004)
        TestFactory.memory(in: ctx, text: "C", lat: 39.90001, lon: 116.40002)

        // 必须同时给 locationName，否则 bucket key 的 name 字段为空（仍会聚一起，但这条更明确）
        for memory in try! ctx.fetch(FetchDescriptor<Memory>()) {
            memory.locationName = "工体"
        }
        try! ctx.save()

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let clusters = LocationClustering.cluster(memories)

        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters[0].memories.count, 3)
        XCTAssertEqual(clusters[0].title, "工体")
    }

    func testFarApartCoordinatesAreSeparateClusters() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "北京", lat: 39.9, lon: 116.4, location: "北京")
        TestFactory.memory(in: ctx, text: "上海", lat: 31.2, lon: 121.5, location: "上海")
        TestFactory.memory(in: ctx, text: "广州", lat: 23.1, lon: 113.3, location: "广州")

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let clusters = LocationClustering.cluster(memories)

        XCTAssertEqual(clusters.count, 3)
    }

    func testSameCoordinateDifferentNameStaySeparate() {
        // 极端情况：同一坐标但 POI 名不同（用户校正过名字）→ 不合并
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "1", lat: 39.9, lon: 116.4, location: "星巴克 A")
        TestFactory.memory(in: ctx, text: "2", lat: 39.9, lon: 116.4, location: "星巴克 B")

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let clusters = LocationClustering.cluster(memories)

        XCTAssertEqual(clusters.count, 2)
    }

    func testClustersSortedByCountDescending() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        // 北京 1 条 / 上海 3 条 / 广州 2 条 → 顺序：上海 > 广州 > 北京
        TestFactory.memory(in: ctx, text: "bj1", lat: 39.9, lon: 116.4, location: "北京")
        for i in 1...3 {
            TestFactory.memory(in: ctx, text: "sh\(i)", lat: 31.2, lon: 121.5, location: "上海")
        }
        for i in 1...2 {
            TestFactory.memory(in: ctx, text: "gz\(i)", lat: 23.1, lon: 113.3, location: "广州")
        }

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let clusters = LocationClustering.cluster(memories)

        XCTAssertEqual(clusters.map(\.title), ["上海", "广州", "北京"])
    }

    func testCoordinateIsAverageOfBucket() {
        let container = TestFactory.makeContainer()
        let ctx = container.mainContext

        TestFactory.memory(in: ctx, text: "1", lat: 39.90000, lon: 116.40000, location: "X")
        TestFactory.memory(in: ctx, text: "2", lat: 39.90004, lon: 116.40004, location: "X")

        let memories = try! ctx.fetch(FetchDescriptor<Memory>())
        let clusters = LocationClustering.cluster(memories)

        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters[0].coordinate.latitude, 39.90002, accuracy: 1e-6)
        XCTAssertEqual(clusters[0].coordinate.longitude, 116.40002, accuracy: 1e-6)
    }
}
