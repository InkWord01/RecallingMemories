//
//  Attachment.swift
//  拾忆
//
//  媒体附件 —— 升级为 @Model 以支持 CloudKit Asset 同步
//
//  双写策略：
//   - imageData: 用 @Attribute(.externalStorage) 存到外部文件，CloudKit 自动映射成 CKAsset
//   - path:      本地相对路径，让 ImageRenderer / PDF / Widget 等不能走 SwiftData 的代码继续工作
//
//  读图优先级：path 本地文件 > imageData（迁移期数据）
//

import Foundation
import SwiftData

@Model
final class Attachment {
    var id: UUID = UUID()

    /// 媒体类型（用 String 存以兼容 SwiftData Codable）
    var kindRaw: String = Kind.photo.rawValue

    /// 本地相对路径（保留以兼容 Widget / ImageRenderer / 老数据）
    var path: String = ""

    /// 缩略图相对路径（仅视频用）
    var thumbnailPath: String?

    /// 时长（秒），仅视频
    var duration: TimeInterval?

    /// 创建时间（用于排序）
    var createdAt: Date = Date()

    /// 媒体二进制数据 — externalStorage 让 SwiftData 把它存到外部文件，
    /// CloudKit 同步时自动映射为 CKAsset。
    /// 双写：persist 时同时写本地文件 + 填充此字段。
    @Attribute(.externalStorage) var imageData: Data?

    /// 反向关系：归属 Memory（inverse 在 Memory.attachments 端声明）
    var memory: Memory?

    init(
        id: UUID = UUID(),
        kind: Kind = .photo,
        path: String = "",
        thumbnailPath: String? = nil,
        duration: TimeInterval? = nil,
        imageData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.path = path
        self.thumbnailPath = thumbnailPath
        self.duration = duration
        self.imageData = imageData
        self.createdAt = createdAt
    }

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .photo }
        set { kindRaw = newValue.rawValue }
    }

    enum Kind: String, Codable {
        case photo
        case livePhoto
        case video
        case audio
    }
}

extension Attachment: Identifiable {}
