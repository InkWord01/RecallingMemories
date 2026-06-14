//
//  ShareCardRenderer.swift
//  拾忆
//
//  将一条 Memory 渲染为适合朋友圈分享的 3:4 精美卡片
//  支持多种模板（极简 / 拍立得 / 卡纸），后续可扩展为 Pro 订阅模板库
//

import SwiftUI
import UIKit

/// 卡片模板
enum ShareCardTemplate: String, CaseIterable, Identifiable {
    // 免费模板
    case minimal      // 极简：渐变 + 大字
    case polaroid     // 拍立得：白边 + 主图 + 手写字
    case kraft        // 卡纸：复古色调 + 衬线字

    // Pro 模板（占位 — 待开发，付费策略待定）
    case magazine     // 杂志风：双栏排版 + 大标题
    case film         // 胶片：35mm 暗房风
    case ink          // 水墨：东方留白
    case neon         // 霓虹：赛博夜景

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimal:  return "极简"
        case .polaroid: return "拍立得"
        case .kraft:    return "卡纸"
        case .magazine: return "杂志"
        case .film:     return "胶片"
        case .ink:      return "水墨"
        case .neon:     return "霓虹"
        }
    }

    /// 是否 Pro 模板（敬请期待，付费策略待定）
    var isPro: Bool {
        switch self {
        case .minimal, .polaroid, .kraft: return false
        case .magazine, .film, .ink, .neon: return true
        }
    }

    /// 模板预览的 SF Symbol 图标
    var icon: String {
        switch self {
        case .minimal:  return "square"
        case .polaroid: return "photo"
        case .kraft:    return "doc.richtext"
        case .magazine: return "newspaper"
        case .film:     return "film"
        case .ink:      return "scribble.variable"
        case .neon:     return "sparkle"
        }
    }
}

enum ShareCardRenderer {

    /// 渲染卡片为 UIImage（朋友圈推荐 3:4 比例 1080x1440）
    @MainActor
    static func render(memory: Memory,
                       template: ShareCardTemplate = .minimal,
                       size: CGSize = CGSize(width: 1080, height: 1440)) -> UIImage? {
        // Pro 模板尚未实现，回退到极简，外层 UI 会拦截不让选中此分支
        let actual = template.isPro ? .minimal : template
        let view = ShareCardView(memory: memory, template: actual)
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        return renderer.uiImage
    }
}

// MARK: - 卡片本体（可独立预览）

struct ShareCardView: View {
    let memory: Memory
    var template: ShareCardTemplate = .minimal

    var body: some View {
        switch template {
        case .minimal:  MinimalCard(memory: memory)
        case .polaroid: PolaroidCard(memory: memory)
        case .kraft:    KraftCard(memory: memory)
        // Pro 模板占位：实际不会渲染（render() 已回退）；保留 case 以编译完整
        case .magazine, .film, .ink, .neon: MinimalCard(memory: memory)
        }
    }
}

// MARK: - 极简模板

private struct MinimalCard: View {
    let memory: Memory

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部时空信息
            VStack(alignment: .leading, spacing: 12) {
                Text(memory.createdAt, format: .dateTime.year().month().day())
                    .font(.system(size: 36, weight: .light, design: .serif))
                if let location = memory.locationName {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                        Text(location)
                    }
                    .font(.system(size: 28, weight: .light))
                }
                Text(memory.createdAt, format: .dateTime.hour().minute())
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .foregroundStyle(.white.opacity(0.85))

            Spacer(minLength: 60)

            // 主文本
            if !memory.text.isEmpty {
                Text(memory.text)
                    .font(.system(size: 56, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .lineSpacing(14)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 媒体（首图）
            if let cover = firstImage() {
                Spacer(minLength: 40)
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 480)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }

            Spacer()

            // 人物
            if !memory.people.isEmpty {
                peopleRow
                    .padding(.bottom, 20)
            }

            // 底部品牌
            HStack {
                if let mood = memory.moodTag {
                    Text(mood).font(.system(size: 28))
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("拾忆")
                        .font(.system(size: 22, weight: .light, design: .serif))
                }
                .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(80)
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.16),
                         Color(red: 0.16, green: 0.10, blue: 0.22)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var peopleRow: some View {
        HStack(spacing: -8) {
            ForEach(memory.people.prefix(5)) { person in
                CardAvatar(name: person.name)
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 2))
            }
            if memory.people.count > 5 {
                Text("+\(memory.people.count - 5)")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.15), in: Circle())
            }
            Text("和 \(memory.people.count) 人")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.leading, 16)
        }
    }

    private func firstImage() -> UIImage? {
        guard let first = memory.sortedAttachments.first(where: { $0.kind != .audio }) else { return nil }
        guard let data = AttachmentStore.loadData(for: first) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - 拍立得模板

private struct PolaroidCard: View {
    let memory: Memory

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 80)
            polaroidPhoto
            Spacer(minLength: 40)
            Text("拾忆 · ")
                .font(.system(size: 22, design: .serif))
                .foregroundStyle(.black.opacity(0.5))
                + Text(memory.createdAt, format: .dateTime.year().month().day())
                    .font(.system(size: 22, design: .serif))
                    .foregroundStyle(.black.opacity(0.5))
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.96, green: 0.94, blue: 0.90))
    }

    private var polaroidPhoto: some View {
        VStack(spacing: 0) {
            // 图像区
            ZStack {
                Color.gray.opacity(0.1)
                if let image = firstImage() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let mood = memory.moodTag {
                    Text(mood).font(.system(size: 200))
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 120))
                        .foregroundStyle(.gray.opacity(0.4))
                }
            }
            .frame(width: 760, height: 760)
            .clipped()

            // 文字区
            VStack(alignment: .leading, spacing: 14) {
                if !memory.text.isEmpty {
                    Text(memory.text)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.black.opacity(0.85))
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }
                HStack(spacing: 12) {
                    if let location = memory.locationName {
                        Label(location, systemImage: "location.fill")
                    }
                    Spacer()
                    if let mood = memory.moodTag, !memory.text.isEmpty {
                        Text(mood)
                    }
                }
                .font(.system(size: 22))
                .foregroundStyle(.black.opacity(0.5))
            }
            .frame(width: 760, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 36)
        }
        .background(.white)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 12)
        .rotationEffect(.degrees(-2))
    }

    private func firstImage() -> UIImage? {
        guard let first = memory.sortedAttachments.first(where: { $0.kind != .audio }) else { return nil }
        guard let data = AttachmentStore.loadData(for: first) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - 卡纸模板

private struct KraftCard: View {
    let memory: Memory

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // 顶部
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(memory.createdAt, format: .dateTime.year())
                        .font(.system(size: 28, weight: .light, design: .serif))
                    Text(memory.createdAt, format: .dateTime.month().day())
                        .font(.system(size: 56, weight: .bold, design: .serif))
                }
                Spacer()
                if let mood = memory.moodTag {
                    Text(mood).font(.system(size: 40))
                }
            }
            .foregroundStyle(Color(red: 0.32, green: 0.22, blue: 0.16))

            Divider().background(Color(red: 0.32, green: 0.22, blue: 0.16))

            // 文字
            if !memory.text.isEmpty {
                Text(memory.text)
                    .font(.system(size: 48, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.08))
                    .lineSpacing(12)
            }

            // 元信息
            VStack(alignment: .leading, spacing: 14) {
                if let location = memory.locationName {
                    Label(location, systemImage: "location.fill")
                        .font(.system(size: 26, design: .serif))
                }
                if !memory.people.isEmpty {
                    Label(memory.people.map(\.name).joined(separator: " · "),
                          systemImage: "person.2.fill")
                        .font(.system(size: 26, design: .serif))
                }
            }
            .foregroundStyle(Color(red: 0.32, green: 0.22, blue: 0.16))

            Spacer()

            // 底部品牌
            HStack {
                Spacer()
                Text("— 拾忆 RecallingMemories —")
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundStyle(Color(red: 0.32, green: 0.22, blue: 0.16).opacity(0.6))
            }
        }
        .padding(80)
        .background(
            ZStack {
                Color(red: 0.92, green: 0.86, blue: 0.74)
                // 噪点纹理（用半透明圆点近似）
                GeometryReader { geo in
                    Canvas { ctx, size in
                        for _ in 0..<300 {
                            let x = Double.random(in: 0...size.width)
                            let y = Double.random(in: 0...size.height)
                            let r = Double.random(in: 0.5...2)
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                                with: .color(Color(red: 0.32, green: 0.22, blue: 0.16).opacity(0.08))
                            )
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        )
    }
}

// MARK: - 卡片专用头像（不依赖 SwiftData，避免渲染时上下文问题）

private struct CardAvatar: View {
    let name: String

    var body: some View {
        Circle()
            .fill(Color(hue: hue, saturation: 0.5, brightness: 0.7))
            .overlay(
                Text(String(name.prefix(1)))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            )
    }

    private var hue: Double {
        let h = abs(name.hashValue % 360)
        return Double(h) / 360.0
    }
}
