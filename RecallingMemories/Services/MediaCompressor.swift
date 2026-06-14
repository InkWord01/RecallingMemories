//
//  MediaCompressor.swift
//  拾忆
//
//  媒体压缩 — 照片重采样 + JPEG 重编码；视频 720p H.264 + 时长截断
//
//  设计原则：
//   1. 压缩失败时调用方有 fallback 路径（保留原始数据），不丢用户内容
//   2. 用 ImageIO 的 CGImageSource thumbnail API，比 UIImage 解码更省内存
//   3. 视频时长在 init.txt 3.1 节明示「30 秒内，聚焦当下」
//

import Foundation
import UIKit
import AVFoundation
import ImageIO

enum MediaCompressor {

    // MARK: - 配置

    enum ImageConfig {
        /// 长边像素上限 — iPhone 15 Pro Max 屏 1290x2796，2048 已绰绰有余
        static let maxDimension: CGFloat = 2048
        /// JPEG 压缩质量 — 0.85 视觉接近无损，体积约为原图 30%
        static let jpegQuality: CGFloat = 0.85
    }

    enum VideoConfig {
        /// 时长上限（秒） — 产品要求"聚焦当下"
        static let maxDuration: TimeInterval = 30
        /// 编码预设 — 1280x720 H.264，30 秒约 8-12 MB
        static let preset: String = AVAssetExportPreset1280x720
    }

    // MARK: - 图片压缩

    /// 把任意输入数据（HEIC / PNG / JPEG）压成统一 JPEG，长边 ≤ maxDimension
    /// - Returns: 压缩后的 JPEG Data；失败返回 nil（调用方应回退到原 data）
    static func compressImage(_ data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        // ImageIO thumbnail API：边解码边降采样，比 UIImage(data:).resize 内存友好得多
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: ImageConfig.maxDimension,
            kCGImageSourceCreateThumbnailWithTransform: true   // 保留 EXIF 旋转
        ]
        guard let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: thumb).jpegData(compressionQuality: ImageConfig.jpegQuality)
    }

    // MARK: - 视频压缩

    /// 把视频压成 720p H.264 mp4，超过 maxDuration 部分截断
    /// - Throws: AVFoundation 错误；调用方失败时应回退到拷贝原文件
    static func compressVideo(from sourceURL: URL, to outputURL: URL) async throws {
        let asset = AVURLAsset(url: sourceURL)
        guard let session = AVAssetExportSession(asset: asset, presetName: VideoConfig.preset) else {
            throw NSError(domain: "MediaCompressor", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法创建视频压缩会话"])
        }

        // 计算实际导出时长（min(原片, 30s)）
        let originalSeconds = try await asset.load(.duration).seconds
        let actualSeconds = min(originalSeconds, VideoConfig.maxDuration)
        session.timeRange = CMTimeRange(
            start: .zero,
            duration: CMTime(seconds: actualSeconds, preferredTimescale: 600)
        )

        // 清理目标位置（如有残留）
        try? FileManager.default.removeItem(at: outputURL)
        session.outputURL = outputURL
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = true   // 让 moov atom 前置，便于流式播放

        // iOS 17 兼容：用老的 callback API + Continuation 包装为 async
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            session.exportAsynchronously {
                switch session.status {
                case .completed:
                    cont.resume()
                case .failed:
                    cont.resume(throwing: session.error ?? NSError(
                        domain: "MediaCompressor", code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "视频压缩失败"]))
                case .cancelled:
                    cont.resume(throwing: NSError(
                        domain: "MediaCompressor", code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "视频压缩被取消"]))
                default:
                    cont.resume(throwing: NSError(
                        domain: "MediaCompressor", code: -4,
                        userInfo: [NSLocalizedDescriptionKey: "视频压缩未完成（状态：\(session.status.rawValue)）"]))
                }
            }
        }
    }
}
