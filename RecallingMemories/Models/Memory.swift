//
//  Memory.swift
//  拾忆
//
//  核心数据模型 — 一条「记忆」记录
//
//  设计约束：所有字段可选 / 有默认值；关系含 inverse；不使用 @Attribute(.unique)
//  —— 让 SwiftData 既能走纯本地，也能走 CloudKit 同步。
//

import Foundation
import SwiftData

@Model
final class Memory {
    /// 主键（不再使用 .unique，由调用方保证 UUID 唯一性）
    var id: UUID = UUID()

    /// 文字内容
    var text: String = ""

    /// 创建时间（精确到秒）
    var createdAt: Date = Date()

    /// 位置 — POI 名称（如：星巴克·国贸店）
    var locationName: String?
    var latitude: Double?
    var longitude: Double?

    /// 天气图标（如：sun.max.fill）
    var weatherIcon: String?

    /// 情绪标签（💡顿悟 / 🔥激动 / 😌平静）
    var moodTag: String?

    /// 关联人物（CloudKit 要求关系含 inverse）
    @Relationship(deleteRule: .nullify, inverse: \Person.memories)
    var people: [Person] = []

    /// 媒体附件 —— 删除 Memory 时级联删除附件
    @Relationship(deleteRule: .cascade, inverse: \Attachment.memory)
    var attachments: [Attachment] = []

    /// 自定义标签
    var tags: [String] = []

    init(
        id: UUID = UUID(),
        text: String = "",
        createdAt: Date = Date(),
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        weatherIcon: String? = nil,
        moodTag: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.weatherIcon = weatherIcon
        self.moodTag = moodTag
        self.tags = tags
    }
}

extension Memory: Identifiable {}
