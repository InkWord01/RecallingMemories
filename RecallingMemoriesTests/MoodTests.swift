//
//  MoodTests.swift
//  RecallingMemoriesTests
//

import XCTest
@testable import RecallingMemories

final class MoodTests: XCTestCase {

    func testStripsEmojiAndKeepsChinese() {
        XCTAssertEqual(Mood.accessibilityLabel(for: "💡顿悟"), "情绪：顿悟")
        XCTAssertEqual(Mood.accessibilityLabel(for: "🔥激动"), "情绪：激动")
        XCTAssertEqual(Mood.accessibilityLabel(for: "😌平静"), "情绪：平静")
        XCTAssertEqual(Mood.accessibilityLabel(for: "🌙怅然"), "情绪：怅然")
        XCTAssertEqual(Mood.accessibilityLabel(for: "🌿温柔"), "情绪：温柔")
    }

    func testEmptyOrPureEmojiFallsBackToOriginal() {
        // 没有中文部分时，原样返回（VoiceOver 自己念 emoji 名）
        XCTAssertEqual(Mood.accessibilityLabel(for: "💡"), "💡")
        XCTAssertEqual(Mood.accessibilityLabel(for: ""), "")
    }

    func testPureChinesePassesThrough() {
        XCTAssertEqual(Mood.accessibilityLabel(for: "顿悟"), "情绪：顿悟")
    }
}
