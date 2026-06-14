//
//  PDFExporter.swift
//  拾忆
//
//  把记忆导出为 PDF 时光书 — A4 比例，封面 + 按月分章 + 排版精美
//

import Foundation
import SwiftUI
import PDFKit
import UIKit

enum PDFExporter {

    /// A4 纵向 @ 72 DPI（PDF 默认单位：点 = 1/72 英寸）
    static let pageSize = CGSize(width: 595, height: 842)

    /// 把 memories 渲染为 PDF 文件，写入临时目录，返回 URL
    @MainActor
    static func write(memories: [Memory], title: String = "拾忆 · 时光书") throws -> URL {
        let stamp = stampString()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("拾忆_\(stamp).pdf")

        let pages = makePages(memories: memories, title: title)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        try renderer.writePDF(to: url) { context in
            for page in pages {
                context.beginPage()
                let imageRenderer = ImageRenderer(content: page.frame(width: pageSize.width, height: pageSize.height))
                imageRenderer.proposedSize = ProposedViewSize(width: pageSize.width, height: pageSize.height)
                if let image = imageRenderer.uiImage {
                    image.draw(in: CGRect(origin: .zero, size: pageSize))
                }
            }
        }

        return url
    }

    // MARK: - 页面构造

    /// 生成全部页面（封面 + 章节封面 + 内容页）
    @MainActor
    private static func makePages(memories: [Memory], title: String) -> [AnyView] {
        var pages: [AnyView] = [AnyView(CoverPage(title: title, count: memories.count))]

        let sorted = memories.sorted { $0.createdAt < $1.createdAt }
        let cal = Calendar.current
        let grouped = Dictionary(grouping: sorted) { memory -> Int in
            let comps = cal.dateComponents([.year, .month], from: memory.createdAt)
            return (comps.year ?? 0) * 100 + (comps.month ?? 0)
        }

        for key in grouped.keys.sorted() {
            guard let items = grouped[key] else { continue }
            let year = key / 100
            let month = key % 100
            pages.append(AnyView(ChapterCover(year: year, month: month, count: items.count)))
            for chunk in items.chunked(into: 2) {
                pages.append(AnyView(MemoriesPage(memories: chunk)))
            }
        }
        return pages
    }

    private static func stampString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: Date())
    }
}

// MARK: - Pages

private struct CoverPage: View {
    let title: String
    let count: Int

    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.tint)
            Text(title)
                .font(.system(size: 36, weight: .light, design: .serif))
                .foregroundStyle(.primary)
            Text("收录 \(count) 条记忆")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            Spacer()
            Text(Date(), format: .dateTime.year().month().day())
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

private struct ChapterCover: View {
    let year: Int
    let month: Int
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer()
            Text(String(format: "%d", year))
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundStyle(.secondary)
            Text("\(month) 月")
                .font(.system(size: 80, weight: .bold, design: .serif))
                .foregroundStyle(.primary)
            Text("\(count) 条记忆")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
    }
}

private struct MemoriesPage: View {
    let memories: [Memory]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(memories) { memory in
                MemoryBlock(memory: memory)
                if memory.id != memories.last?.id {
                    Divider()
                }
            }
            Spacer()
        }
        .padding(.horizontal, 50)
        .padding(.vertical, 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.background)
    }
}

private struct MemoryBlock: View {
    let memory: Memory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 时间 + 情绪
            HStack(spacing: 6) {
                Text(memory.createdAt, format: .dateTime.month().day().hour().minute())
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(.secondary)
                if let mood = memory.moodTag {
                    Text(mood).font(.system(size: 14))
                }
                Spacer()
            }

            // 文字
            if !memory.text.isEmpty {
                Text(memory.text)
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .lineLimit(8)
            }

            // 首张配图
            if let first = memory.attachments.first(where: { $0.kind != .audio }),
               let image = UIImage(contentsOfFile: AttachmentStore.url(for: first).path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // 元信息
            HStack(spacing: 10) {
                if let location = memory.locationName {
                    Label(location, systemImage: "location.fill")
                }
                if !memory.people.isEmpty {
                    Label(memory.people.map(\.name).joined(separator: "、"),
                          systemImage: "person.2.fill")
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
    }
}

// MARK: - 工具

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
