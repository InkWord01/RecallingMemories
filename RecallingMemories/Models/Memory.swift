//
//  Memory.swift
//  拾忆
//
//  核心数据模型 — 一条「记忆」记录
//

import Foundation
import SwiftData

@Model
final class Memory {
    /// 主键
    @Attribute(.unique) var id: UUID

    /// 文字内容
    var text: String

    /// 创建时间（精确到秒）
    var createdAt: Date

    /// 位置 — POI 名称（如：星巴克·国贸店）
    var locationName: String?
    var latitude: Double?
    var longitude: Double?

    /// 天气图标（如：sun.max.fill）
    var weatherIcon: String?

    /// 情绪标签（💡顿悟 / 🔥激动 / 😌平静）
    var moodTag: String?

    /// 关联人物
    @Relationship(deleteRule: .nullify) var people: [Person] = []

    /// 媒体附件 (照片/视频本地路径或 CloudKit assetID)
    var attachments: [Attachment]

    /// 自定义标签
    var tags: [String]

    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date(),
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        weatherIcon: String? = nil,
        moodTag: String? = nil,
        attachments: [Attachment] = [],
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
        self.attachments = attachments
        self.tags = tags
    }
}

// SwiftData @Model 不自动 conform Identifiable；显式 conform 让 SwiftUI ForEach / sheet(item:) 直接接受
extension Memory: Identifiable {}

/// 媒体附件
struct Attachment: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var kind: Kind
    /// 本地相对路径或 iCloud assetIdentifier
    var path: String
    /// 缩略图相对路径
    var thumbnailPath: String?
    /// 时长（秒），仅视频
    var duration: TimeInterval?

    enum Kind: String, Codable {
        case photo
        case livePhoto
        case video
        case audio
    }
}
