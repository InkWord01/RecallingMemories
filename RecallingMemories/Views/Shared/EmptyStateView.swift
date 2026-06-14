//
//  EmptyStateView.swift
//  拾忆
//
//  统一的空态视图 — 图标 + 标题 + 副标题 + 行动按钮
//  比 ContentUnavailableView 多一个可点的 CTA，把空态变成引导
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var primaryAction: (label: String, action: () -> Void)?
    var secondaryHint: String?

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .fill(.tint.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.bold())
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let action = primaryAction {
                Button(action: action.action) {
                    Text(action.label)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.tint, in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }

            if let hint = secondaryHint {
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("无 CTA") {
    EmptyStateView(
        icon: "calendar.badge.clock",
        title: "今天还没有那年今日",
        message: "一年后再来这里，会看到今天留下的痕迹。"
    )
}

#Preview("带 CTA") {
    EmptyStateView(
        icon: "sparkles",
        title: "还没有记忆",
        message: "把第一个想法、第一张照片、第一个地点留下来。",
        primaryAction: ("立即记录", {}),
        secondaryHint: "在「记录」页随手写一句也行"
    )
}
