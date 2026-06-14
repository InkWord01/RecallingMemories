//
//  TestFactory.swift
//  RecallingMemoriesTests
//
//  共享的 SwiftData 测试容器 + 便捷的 Memory/Person 构造器
//
//  XCTest 不能直接 new SwiftData @Model；必须通过 ModelContainer/Context。
//  这里提供 in-memory 容器与 fixture builder，让测试函数像 plain unit 一样易写。
//

import Foundation
import SwiftData
@testable import RecallingMemories

@MainActor
enum TestFactory {

    /// 每次调用返回一个全新的 in-memory 容器（独立隔离，避免测试间污染）
    static func makeContainer() -> ModelContainer {
        let schema = Schema([Memory.self, Person.self, Attachment.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: config)
    }

    /// 构造一条 Memory 并插入容器
    @discardableResult
    static func memory(in context: ModelContext,
                       text: String = "",
                       at date: Date = Date(),
                       location: String? = nil,
                       lat: Double? = nil,
                       lon: Double? = nil,
                       mood: String? = nil,
                       tags: [String] = [],
                       people: [Person] = [],
                       attachments: [Attachment] = []) -> Memory {
        let memory = Memory(
            text: text,
            createdAt: date,
            locationName: location,
            latitude: lat,
            longitude: lon,
            moodTag: mood,
            tags: tags
        )
        memory.people = people
        context.insert(memory)
        // Attachment 是 @Model，需要 insert 到 context 并设关系
        for attachment in attachments {
            context.insert(attachment)
            attachment.memory = memory
        }
        return memory
    }

    /// 构造一个 Person 并插入容器
    @discardableResult
    static func person(in context: ModelContext, name: String) -> Person {
        let person = Person(name: name)
        context.insert(person)
        return person
    }

    /// 构造一个 photo 附件（仅模型，不写盘）
    static func photoAttachment(filename: String = "test.jpg") -> Attachment {
        Attachment(kind: .photo, path: filename)
    }
}

extension Date {
    /// 测试便捷构造：`.at(2026, 6, 14, hour: 9)`
    static func at(_ year: Int, _ month: Int, _ day: Int,
                   hour: Int = 12, minute: Int = 0,
                   calendar: Calendar = .current) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        // swiftlint:disable:next force_unwrapping
        return calendar.date(from: components)!
    }
}
