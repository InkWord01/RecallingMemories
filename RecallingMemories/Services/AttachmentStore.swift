//
//  AttachmentStore.swift
//  拾忆
//
//  附件本地存储 — 把 PhotosPicker 选中的媒体压缩后写入 App 沙盒 + 填充 SwiftData externalStorage
//
//  压缩策略（由 MediaCompressor 实现，本类负责落盘）：
//   - 图片：HEIC/PNG/JPEG 统一重采样到 ≤2048px 长边的 JPEG，质量 0.85
//   - 视频：720p H.264 mp4，最长 30s
//   - 失败时优雅降级到原始数据，不丢用户内容
//

import Foundation
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

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

    /// 临时目录（视频压缩前先把原始数据落到这里，压完再删）
    private static var tempURL: URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AttachmentStaging", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 把 PhotosPickerItem 持久化：压缩 → 写本地文件 → 返回带 imageData 的 Attachment
    /// - Parameter includeCloudData: 是否填充 imageData 让 CloudKit 同步媒体；默认 false
    static func persist(_ item: PhotosPickerItem, includeCloudData: Bool = false) async throws -> Attachment {
        guard let originalData = try await item.loadTransferable(type: Data.self) else {
            throw NSError(domain: "AttachmentStore", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法读取媒体数据"])
        }

        // 推断类型 —— 视频走专门路径，其它都按图片处理
        let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) })
        let isLivePhoto = item.supportedContentTypes.contains(where: { $0.conforms(to: .livePhoto) })

        let id = UUID()
        return try await isVideo
            ? persistVideo(originalData: originalData, id: id, includeCloudData: includeCloudData)
            : persistImage(originalData: originalData, id: id, kind: isLivePhoto ? .livePhoto : .photo,
                           includeCloudData: includeCloudData)
    }

    // MARK: - 图片路径

    private static func persistImage(originalData: Data,
                                     id: UUID,
                                     kind: Attachment.Kind,
                                     includeCloudData: Bool) async throws -> Attachment {
        // 压缩失败时回退到原始数据 —— 用户的图永远不丢
        let finalData = MediaCompressor.compressImage(originalData) ?? originalData

        let filename = "\(id.uuidString).jpg"
        let url = rootURL.appendingPathComponent(filename)
        try finalData.write(to: url, options: .atomic)

        return Attachment(
            id: id,
            kind: kind,
            path: filename,
            thumbnailPath: nil,
            duration: nil,
            imageData: includeCloudData ? finalData : nil
        )
    }

    // MARK: - 视频路径

    private static func persistVideo(originalData: Data,
                                     id: UUID,
                                     includeCloudData: Bool) async throws -> Attachment {
        // AVAssetExportSession 需要文件输入 —— 先把原始数据落到临时目录
        let stagingURL = tempURL.appendingPathComponent("\(id.uuidString)-src.mov")
        try originalData.write(to: stagingURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: stagingURL) }

        let filename = "\(id.uuidString).mp4"
        let outputURL = rootURL.appendingPathComponent(filename)

        var compressedDuration: TimeInterval?
        do {
            try await MediaCompressor.compressVideo(from: stagingURL, to: outputURL)
            // 读出实际导出时长
            let asset = AVURLAsset(url: outputURL)
            compressedDuration = try? await asset.load(.duration).seconds
        } catch {
            // 压缩失败：回退到原始数据，至少保留用户挂载的内容
            try originalData.write(to: outputURL, options: .atomic)
        }

        // 视频不上云（即使开启云同步也跳过 — 体积过大）
        return Attachment(
            id: id,
            kind: .video,
            path: filename,
            thumbnailPath: nil,
            duration: compressedDuration,
            imageData: nil
        )
    }

    // MARK: - 读取

    /// 解析 Attachment 到本地 URL（用于显示）
    static func url(for attachment: Attachment) -> URL {
        rootURL.appendingPathComponent(attachment.path)
    }

    /// 加载 Attachment 数据 — 优先本地文件，缺失时回落到云端 imageData 并写回本地
    static func loadData(for attachment: Attachment) -> Data? {
        let localURL = url(for: attachment)
        if let data = try? Data(contentsOf: localURL) {
            return data
        }
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
