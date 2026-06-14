//
//  LegalDocumentView.swift
//  拾忆
//
//  统一的法律文档展示视图 — 隐私协议 / 用户协议 / 第三方致谢都走这一个
//
//  设计取舍：
//   1. 文案直接内联在 Swift 里，不用本地化文件 — MVP 期方便快速调整；后续切 .strings
//   2. 用 markdown 子集渲染（## / 列表 / 强调），手撸一个轻量解析器，避免引第三方
//

import SwiftUI

/// 一个文档由多个区段构成
struct LegalDocument {
    let title: String
    let lastUpdated: String  // 例: "2026 年 6 月 14 日"
    let sections: [Section]

    struct Section: Identifiable {
        let id = UUID()
        let heading: String
        let body: [Block]
    }

    enum Block {
        case paragraph(String)
        case bullet([String])      // 无序列表
        case emphasis(String)      // 加粗 / 强调段
    }
}

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 顶部
                VStack(alignment: .leading, spacing: 6) {
                    Text(document.title)
                        .font(.title2.bold())
                    Text("最后更新：\(document.lastUpdated)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // 区段
                ForEach(document.sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.heading)
                            .font(.headline)
                            .padding(.top, 4)

                        ForEach(Array(section.body.enumerated()), id: \.offset) { _, block in
                            blockView(block)
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func blockView(_ block: LegalDocument.Block) -> some View {
        switch block {
        case .paragraph(let text):
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .bullet(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(item)
                            .font(.body)
                            .lineSpacing(3)
                    }
                }
            }

        case .emphasis(let text):
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
    }
}
