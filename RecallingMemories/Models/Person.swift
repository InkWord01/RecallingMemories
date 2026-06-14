//
//  Person.swift
//  拾忆
//
//  人物标签 — 「和谁在一起」
//

import Foundation
import SwiftData

@Model
final class Person {
    @Attribute(.unique) var id: UUID
    var name: String
    /// 来自系统通讯录的 contactIdentifier (可选)
    var contactIdentifier: String?
    /// 头像本地路径
    var avatarPath: String?

    init(id: UUID = UUID(), name: String, contactIdentifier: String? = nil, avatarPath: String? = nil) {
        self.id = id
        self.name = name
        self.contactIdentifier = contactIdentifier
        self.avatarPath = avatarPath
    }
}
