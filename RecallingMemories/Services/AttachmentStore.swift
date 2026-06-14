//
//  AttachmentStore.swift
//  拾忆
//
//  附件本地存储 — 把 PhotosPicker 选中的媒体写入 App 沙盒 + 填充 SwiftData externalStorage
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

    /// 把 PhotosPickerItem 持久化：写本地文件 + 返回带 imageData 的 Attachment
    /// - Parameter includeCloudData: 是否填充 imageData 让 CloudKit 同步媒体；默认 false（仅本地）
    static func persist(_ item: PhotosPickerItem, includeCloudData: Bool = false) async throws -> Attachment {
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

        // 视频不上云（流量大且 CloudKit Asset 上传慢）—— 仅图片填充 imageData
        let cloudData: Data? = (includeCloudData && kind != .video) ? data : nil

        return Attachment(
            id: id,
            kind: kind,
            path: filename,
            thumbnailPath: nil,
            duration: nil,
            imageData: cloudData
        )
    }

    /// 解析 Attachment 到本地 URL（用于显示）
    static func url(for attachment: Attachment) -> URL {
        rootURL.appendingPathComponent(attachment.path)
    }

    /// 加载 Attachment 数据 — 优先本地文件，缺失时回落到云端 imageData
    /// 用于跨设备场景：另一台设备只有 SwiftData 同步过来的 imageData，没有本地文件
    static func loadData(for attachment: Attachment) -> Data? {
        let localURL = url(for: attachment)
        if let data = try? Data(contentsOf: localURL) {
            return data
        }
        // 本地文件不存在 → 回落到 SwiftData externalStorage，并把数据回写本地
        if let cloudData = attachment.imageData {
            try? cloudData.write(to: localURL, options: .atomic)
            return cloudData
        }
        return nil
    }

    /// 删除附件文件 — Memory 删除时由调用方负责（cascade 不会自动清磁盘）
    static func deleteFile(for attachment: Attachment) {
        try? FileManager.default.removeItem(at: url(for: attachment))
    }
}
