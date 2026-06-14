//
//  AttachmentStore.swift
//  拾忆
//
//  附件本地存储 — 将 PhotosPicker 选中的媒体写入 App 沙盒 Documents/Attachments/
//

import Foundation
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

enum AttachmentStore {

    /// 附件根目录
    static var rootURL: URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("Attachments", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 将 PhotosPickerItem 持久化为本地文件，返回 Attachment
    static func persist(_ item: PhotosPickerItem) async throws -> Attachment {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw NSError(domain: "AttachmentStore", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法读取媒体数据"])
        }

        // 推断类型
        let kind: Attachment.Kind
        let ext: String
        if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
            kind = .video
            ext = "mov"
        } else if item.supportedContentTypes.contains(where: { $0.conforms(to: .livePhoto) }) {
            kind = .livePhoto
            ext = "jpg"
        } else {
            kind = .photo
            ext = "jpg"
        }

        let id = UUID()
        let filename = "\(id.uuidString).\(ext)"
        let url = rootURL.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)

        return Attachment(id: id, kind: kind, path: filename, thumbnailPath: nil, duration: nil)
    }

    /// 解析 Attachment 到本地 URL（用于显示）
    static func url(for attachment: Attachment) -> URL {
        rootURL.appendingPathComponent(attachment.path)
    }
}
