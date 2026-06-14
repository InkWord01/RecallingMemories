//
//  AboutView.swift
//  拾忆
//
//  关于页面 — App 信息 / 作者 / 设计理念 / 联系方式
//

import SwiftUI

struct AboutView: View {
    @State private var tapCount: Int = 0
    @State private var showEasterEgg = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                logoBlock
                taglineBlock
                infoCard
                authorBlock
                creditsBlock
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .alert("🎉", isPresented: $showEasterEgg) {
            Button("好") { tapCount = 0 }
        } message: {
            Text("谢谢你愿意记录此刻。\n这个 App 由一个人在闲暇时间写就，希望它对你有用。\n— 字之")
        }
    }

    // MARK: - Logo

    private var logoBlock: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.18))
                    .frame(width: 110, height: 110)
                    .blur(radius: 18)
                Image(systemName: "sparkles")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityHidden(true)
            .onTapGesture {
                tapCount += 1
                if tapCount >= 5 {
                    showEasterEgg = true
                }
            }

            Text(AppInfo.displayName)
                .font(.system(size: 32, weight: .semibold, design: .serif))
            Text(AppInfo.englishName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .tracking(2)
        }
        .padding(.top, 8)
    }

    // MARK: - Tagline

    private var taglineBlock: some View {
        VStack(spacing: 6) {
            Text("基于时空的灵感与记忆捕捉工具")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.85))
            Text("打开就能写。一瞬间的想法，不会从指缝溜走。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(spacing: 0) {
            row(label: "版本", value: AppInfo.marketingVersion)
            divider
            row(label: "构建号", value: AppInfo.buildNumber)
            divider
            row(label: "最低系统", value: "iOS 17.0")
        }
        .padding(.vertical, 4)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(.primary)
                .monospacedDigit()
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.06))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    // MARK: - Author

    private var authorBlock: some View {
        VStack(spacing: 8) {
            Text("作者")
                .font(.caption)
                .foregroundStyle(.secondary)
                .tracking(2)
            Text(AppInfo.author)
                .font(.title3.weight(.medium))
            Text("一个相信「瞬间值得被留下」的工程师")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    // MARK: - Credits

    private var creditsBlock: some View {
        VStack(spacing: 6) {
            Text(AppInfo.copyright)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text("用 SwiftUI 与 SwiftData 构筑")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 12)
    }
}

#Preview {
    NavigationStack { AboutView() }
}
