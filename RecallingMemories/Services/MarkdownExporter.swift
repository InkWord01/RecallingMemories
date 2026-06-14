//
//  MarkdownExporter.swift
//  拾忆
//
//  把记忆导出为 Markdown 时光书 — 按年-月分章，附图片相对路径
//

import Foundation

enum MarkdownExporter {

    /// 把 memories 渲染为单一 Markdown 字符串
    /// - Parameter copyAttachmentsTo: 若提供，会把附件复制到该目录，并在 md 中用相对路径引用
    static func render(memories: [Memory],
                       title: String = "拾忆 · 时光书",
                       copyAttachmentsTo attachmentsDir: URL? = nil) -> String {
        guard !memories.isEmpty else {
            return "# \(title)\n\n_还没有记忆_\n"
        }

        let sorted = memories.sorted { $0.createdAt < $1.createdAt }
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")

        var lines: [String] = []
        lines.append("# \(title)")
        lines.append("")
        lines.append("> 共 \(memories.count) 条记忆，导出于 \(format(Date(), pattern: "yyyy-MM-dd HH:mm"))")
        lines.append("")
        lines.append("---")
        lines.append("")

        // 按 yyyy-MM 分组
        let grouped = Dictionary(grouping: sorted) { memory -> String in
            let comps = cal.dateComponents([.year, .month], from: memory.createdAt)
            return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
        }

        for key in grouped.keys.sorted() {
            guard let items = grouped[key] else { continue }
            f.dateFormat = "yyyy 年 M 月"
            let header = items.first.map { f.string(from: $0.createdAt) } ?? key
            lines.append("## \(header)")
            lines.append("")

            for memory in items {
                lines.append(renderMemory(memory, attachmentsDir: attachmentsDir))
                lines.append("")
                lines.append("---")
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }

    /// 写入 Markdown 文件 + 附件目录到临时位置，并打包成 zip，返回 zip 文件 URL
    static func writeBundle(memories: [Memory],
                            title: String = "拾忆 · 时光书") throws -> URL {
        let fm = FileManager.default
        let stamp = format(Date(), pattern: "yyyyMMdd-HHmmss")
        let workspaceName = "RecallingMemoriesExport-\(stamp)"
        let root = fm.temporaryDirectory
            .appendingPathComponent(workspaceName, isDirectory: true)
        let attachments = root.appendingPathComponent("attachments", isDirectory: true)

        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        try fm.createDirectory(at: attachments, withIntermediateDirectories: true)

        let markdown = render(memories: memories, title: title, copyAttachmentsTo: attachments)
        let mdURL = root.appendingPathComponent("README.md")
        try markdown.data(using: .utf8)?.write(to: mdURL, options: .atomic)

        // 打包成 zip — NSFileCoordinator(.forUploading) 是 iOS 上把目录变 zip 的标准做法
        let zipURL = try archiveDirectoryAsZip(root: root, stamp: stamp)

        // 清理工作目录
        try? fm.removeItem(at: root)
        return zipURL
    }

    /// 用 NSFileCoordinator 把目录打成 zip，返回最终落地的 zip URL
    private static func archiveDirectoryAsZip(root: URL, stamp: String) throws -> URL {
        let fm = FileManager.default
        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        var resultURL: URL?
        var caughtError: Error?

        let intent = NSFileAccessIntent.readingIntent(with: root, options: [.forUploading])
        let group = DispatchGroup()
        group.enter()
        coordinator.coordinate(with: [intent], queue: .global(qos: .userInitiated)) { error in
            defer { group.leave() }
            if let error {
                caughtError = error
                return
            }
            do {
                let dst = fm.temporaryDirectory
                    .appendingPathComponent("拾忆_\(stamp).zip")
                try? fm.removeItem(at: dst)
                try fm.moveItem(at: intent.url, to: dst)
                resultURL = dst
            } catch {
                caughtError = error
            }
        }
        group.wait()

        if let error = caughtError ?? coordError { throw error }
        guard let resultURL else {
            throw NSError(domain: "MarkdownExporter", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "打包 zip 失败"])
        }
        return resultURL
    }

    // MARK: - 内部

    private static func renderMemory(_ memory: Memory, attachmentsDir: URL?) -> String {
        var lines: [String] = []

        // 时间标题（含情绪）
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M 月 d 日 EEEE  HH:mm"
        let timeTitle = f.string(from: memory.createdAt)
        var heading = "### \(timeTitle)"
        if let mood = memory.moodTag { heading += "  \(mood)" }
        lines.append(heading)
        lines.append("")

        // 元信息行
        var meta: [String] = []
        if let location = memory.locationName { meta.append("📍 \(location)") }
        if !memory.people.isEmpty {
            meta.append("👥 \(memory.people.map(\.name).joined(separator: "、"))")
        }
        if !memory.tags.isEmpty {
            meta.append("🏷 " + memory.tags.map { "#\($0)" }.joined(separator: " "))
        }
        if !meta.isEmpty {
            lines.append(meta.joined(separator: "  "))
            lines.append("")
        }

        // 正文
        if !memory.text.isEmpty {
            // 转义 markdown 特殊字符（最小集合）
            let body = memory.text
                .replacingOccurrences(of: "\\", with: "\\\\")
            lines.append(body)
            lines.append("")
        }

        // 附件
        if !memory.attachments.isEmpty {
            for attachment in memory.sortedAttachments {
                let mdPath: String
                if let dir = attachmentsDir {
                    let dst = dir.appendingPathComponent(attachment.path)
                    if !FileManager.default.fileExists(atPath: dst.path) {
                        // 优先从本地复制；本地缺失则尝试 imageData 写一份
                        let src = AttachmentStore.url(for: attachment)
                        if FileManager.default.fileExists(atPath: src.path) {
                            try? FileManager.default.copyItem(at: src, to: dst)
                        } else if let data = attachment.imageData {
                            try? data.write(to: dst, options: .atomic)
                        }
                    }
                    mdPath = "attachments/\(attachment.path)"
                } else {
                    // 单文件模式：不外泄设备路径，仅占位文件名
                    mdPath = "./_missing/\(attachment.path)"
                }
                switch attachment.kind {
                case .photo, .livePhoto:
                    lines.append("![](\(mdPath))")
                case .video:
                    lines.append("🎬 [视频](\(mdPath))")
                case .audio:
                    lines.append("🔊 [音频](\(mdPath))")
                }
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private static func format(_ date: Date, pattern: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = pattern
        return f.string(from: date)
    }
}
