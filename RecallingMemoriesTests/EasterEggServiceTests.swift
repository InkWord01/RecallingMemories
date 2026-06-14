//
//  EasterEggServiceTests.swift
//  RecallingMemoriesTests
//

import XCTest
@testable import RecallingMemories

@MainActor
final class EasterEggServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // 每个用例前清空持久化
        UserDefaults.standard.removeObject(forKey: "RM.easterEgg.unlocked")
        UserDefaults.standard.removeObject(forKey: "RM.debug.unlocked")
        // service 是单例 + private init，无法 isolation；
        // 通过 lock/unlock 强制重置到已知状态
        EasterEggService.shared.lockEgg()
        EasterEggService.shared.lockDebug()
    }

    func testEggInitiallyLocked() {
        XCTAssertFalse(EasterEggService.shared.isEggUnlocked)
    }

    func testUnlockEggIsIdempotent() {
        EasterEggService.shared.unlockEgg()
        XCTAssertTrue(EasterEggService.shared.isEggUnlocked)
        // 再调一次不会出问题
        EasterEggService.shared.unlockEgg()
        XCTAssertTrue(EasterEggService.shared.isEggUnlocked)
    }

    func testLockEggResets() {
        EasterEggService.shared.unlockEgg()
        XCTAssertTrue(EasterEggService.shared.isEggUnlocked)
        EasterEggService.shared.lockEgg()
        XCTAssertFalse(EasterEggService.shared.isEggUnlocked)
    }

    func testDebugLockedByDefault() {
        XCTAssertFalse(EasterEggService.shared.isDebugUnlocked)
    }

    func testUnlockDebugAndLockBack() {
        EasterEggService.shared.unlockDebug()
        XCTAssertTrue(EasterEggService.shared.isDebugUnlocked)
        EasterEggService.shared.lockDebug()
        XCTAssertFalse(EasterEggService.shared.isDebugUnlocked)
    }

    func testEggAndDebugAreIndependent() {
        EasterEggService.shared.unlockEgg()
        XCTAssertTrue(EasterEggService.shared.isEggUnlocked)
        XCTAssertFalse(EasterEggService.shared.isDebugUnlocked)

        EasterEggService.shared.unlockDebug()
        XCTAssertTrue(EasterEggService.shared.isDebugUnlocked)

        EasterEggService.shared.lockEgg()
        XCTAssertFalse(EasterEggService.shared.isEggUnlocked)
        XCTAssertTrue(EasterEggService.shared.isDebugUnlocked, "锁彩蛋不影响调试")
    }
}
