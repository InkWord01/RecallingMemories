//
//  TimeOfDayTests.swift
//  RecallingMemoriesTests
//

import XCTest
@testable import RecallingMemories

final class TimeOfDayTests: XCTestCase {

    private func tod(hour: Int) -> TimeOfDay {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 14
        components.hour = hour
        components.minute = 0
        let date = Calendar.current.date(from: components)!
        return TimeOfDay.now(date: date)
    }

    // MARK: - 边界

    func testMidnightIsLateNight() {
        XCTAssertEqual(tod(hour: 0), .lateNight)
        XCTAssertEqual(tod(hour: 4), .lateNight)
    }

    func testFiveAMIsEarlyMorning() {
        XCTAssertEqual(tod(hour: 5), .earlyMorning)
        XCTAssertEqual(tod(hour: 7), .earlyMorning)
    }

    func testEightAMIsMorning() {
        XCTAssertEqual(tod(hour: 8), .morning)
        XCTAssertEqual(tod(hour: 10), .morning)
    }

    func testElevenAMIsNoon() {
        XCTAssertEqual(tod(hour: 11), .noon)
        XCTAssertEqual(tod(hour: 13), .noon)
    }

    func testTwoPMIsAfternoon() {
        XCTAssertEqual(tod(hour: 14), .afternoon)
        XCTAssertEqual(tod(hour: 16), .afternoon)
    }

    func testFivePMIsDusk() {
        XCTAssertEqual(tod(hour: 17), .dusk)
        XCTAssertEqual(tod(hour: 18), .dusk)
    }

    func testSevenPMIsEvening() {
        XCTAssertEqual(tod(hour: 19), .evening)
        XCTAssertEqual(tod(hour: 21), .evening)
    }

    func testTenPMIsLateNight() {
        // 22-24 归为深夜段，与 0-5 一致
        XCTAssertEqual(tod(hour: 22), .lateNight)
        XCTAssertEqual(tod(hour: 23), .lateNight)
    }

    // MARK: - 文案

    func testGreetingFormat() {
        XCTAssertEqual(TimeOfDay.lateNight.greeting, "深夜的此刻")
        XCTAssertEqual(TimeOfDay.morning.greeting, "上午的此刻")
        XCTAssertEqual(TimeOfDay.dusk.greeting, "黄昏的此刻")
    }

    func testChineseNameNoSuffix() {
        // 「深夜」不应自动带「的此刻」后缀，让其它场景能复用
        XCTAssertEqual(TimeOfDay.lateNight.chineseName, "深夜")
        XCTAssertEqual(TimeOfDay.morning.chineseName, "上午")
    }

    // MARK: - 全部 case 都有 tint

    func testAllCasesHaveTint() {
        for tod in TimeOfDay.allCases {
            // SwiftUI Color 没有 == 比较，但只要不 crash 就 OK
            _ = tod.tint
            XCTAssertFalse(tod.chineseName.isEmpty)
            XCTAssertFalse(tod.greeting.isEmpty)
        }
    }
}
