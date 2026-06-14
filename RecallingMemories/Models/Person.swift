//
//  Person.swift
//  拾忆
//
//  人物标签 — 「和谁在一起」
//
//  CloudKit 兼容：所有字段可选 / 有默认值；含 memories inverse 关系
//

import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID = UUID()
    var name: String = ""
    /// 来自系统通讯录的 contactIdentifier (可选)
    var contactIdentifier: String?
    /// 头像本地路径
    var avatarPath: String?

    /// 反向关系：包含此人的所有记忆（inverse 在 Memory.people 端声明）
    var memories: [Memory] = []

    init(id: UUID = UUID(), name: String = "", contactIdentifier: String? = nil, avatarPath: String? = nil) {
        self.id = id
        self.name = name
        self.contactIdentifier = contactIdentifier
        self.avatarPath = avatarPath
    }
}

extension Person: Identifiable {}
