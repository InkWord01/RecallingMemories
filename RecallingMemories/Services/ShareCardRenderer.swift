//
//  ShareCardRenderer.swift
//  拾忆
//
//  将一条 Memory 渲染为适合朋友圈的 3:4 精美卡片
//

import SwiftUI
import UIKit

enum ShareCardRenderer {

    /// 渲染卡片为 UIImage
    @MainActor
    static func render(memory: Memory, size: CGSize = CGSize(width: 1080, height: 1440)) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(memory: memory).frame(width: size.width, height: size.height))
        renderer.scale = 1.0
        return renderer.uiImage
    }
}

private struct ShareCardView: View {
    let memory: Memory

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 顶部时空信息
            VStack(alignment: .leading, spacing: 8) {
                Text(memory.createdAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.system(size: 32, weight: .light, design: .serif))
                if let loc = memory.locationName {
                    Label(loc, systemImage: "location.fill")
                        .font(.system(size: 28))
                }
            }
            .foregroundStyle(.white.opacity(0.85))

            Spacer(minLength: 40)

            // 主文本
            Text(memory.text)
                .font(.system(size: 56, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .lineSpacing(12)

            Spacer()

            // 底部品牌
            HStack {
                Spacer()
                Text("— 拾忆 ·")
                    .font(.system(size: 24, weight: .light))
                Text(memory.moodTag ?? "")
                    .font(.system(size: 24))
            }
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(80)
        .background(
            LinearGradient(
                colors: [.black, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
