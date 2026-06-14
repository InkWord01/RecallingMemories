//
//  OnboardingView.swift
//  拾忆
//
//  首次启动引导 — 横向翻页介绍核心价值
//
//  细节设计：
//   - 第一页文案根据当前时辰动态切换（深夜/清晨/午后…），
//     让用户第一眼感觉"这个 App 懂当下"
//   - 第一页图标轻微呼吸动画（暗示"瞬间在流动"）
//   - 翻页时自动停止动画，避免视觉过饱和
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page: Int = 0
    /// 进入引导时锁定时辰 — 避免用户翻几页后跨过时辰边界导致文案变换
    @State private var timeOfDay: TimeOfDay = .now()

    private var pages: [Page] {
        [
            Page(
                icon: "sparkles",
                title: timeOfDay.greeting,
                subtitle: "打开就能写。一瞬间的想法，不会从指缝溜走。",
                tint: timeOfDay.tint,
                breathing: true   // 仅首页带呼吸动画
            ),
            Page(
                icon: "location.fill.viewfinder",
                title: "时空都在",
                subtitle: "自动记录在哪、和谁、什么时间。还原此刻的全部语境。",
                tint: Color(red: 0.55, green: 0.85, blue: 1.0)
            ),
            Page(
                icon: "calendar.badge.clock",
                title: "那年今日",
                subtitle: "一年后，今天写下的想法会被悄悄送回来。",
                tint: Color(red: 1.0, green: 0.7, blue: 0.85)
            ),
            Page(
                icon: "lock.shield.fill",
                title: "默认本地存储",
                subtitle: "记忆只保存在你的设备上。是否上云，由你决定。",
                tint: Color(red: 0.7, green: 0.95, blue: 0.7)
            )
        ]
    }

    var body: some View {
        ZStack {
            // 全屏渐变随当前页变化
            LinearGradient(
                colors: [pages[page].tint.opacity(0.25), .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .animation(.easeInOut(duration: 0.4), value: page)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 跳过
                HStack {
                    Spacer()
                    Button("跳过") { onFinish() }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding()
                }

                // 翻页内容
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        OnboardingPageView(
                            page: pages[i],
                            isCurrent: page == i,
                            reduceMotion: reduceMotion
                        )
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // 自定义页码点
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(page == i ? .white : .white.opacity(0.3))
                            .frame(width: page == i ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.bottom, 24)
                .accessibilityElement()
                .accessibilityLabel("第 \(page + 1) 页，共 \(pages.count) 页")

                // 行动按钮
                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "继续" : "开始记录")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white, in: Capsule())
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Page

private struct Page {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    var breathing: Bool = false
}

private struct OnboardingPageView: View {
    let page: Page
    let isCurrent: Bool
    let reduceMotion: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                // 外层光晕 —— 当前页 + 启用呼吸时缓慢脉动
                Circle()
                    .fill(page.tint.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .modifier(BreathingModifier(
                        active: page.breathing && isCurrent && !reduceMotion
                    ))

                Image(systemName: page.icon)
                    .font(.system(size: 96, weight: .light))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityHidden(true)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)

                Text(page.subtitle)
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title)。\(page.subtitle)")
    }
}

// MARK: - 呼吸动画

/// 让附属视图缓慢呼吸 —— scale 0.95 ↔ 1.05，opacity 0.7 ↔ 1.0，1.5 秒一段
private struct BreathingModifier: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.phaseAnimator([0, 1]) { view, phase in
                view
                    .scaleEffect(phase == 0 ? 0.95 : 1.05)
                    .opacity(phase == 0 ? 0.7 : 1.0)
            } animation: { _ in
                .easeInOut(duration: 1.5)
            }
        } else {
            content
        }
    }
}

#Preview("默认") {
    OnboardingView(onFinish: {})
}
