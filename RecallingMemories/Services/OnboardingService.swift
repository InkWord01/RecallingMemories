//
//  OnboardingService.swift
//  拾忆
//
//  控制首次启动引导是否显示 — 用 UserDefaults 存版本号，将来文案大改可强制重弹
//

import Foundation

@MainActor
final class OnboardingService: ObservableObject {
    static let shared = OnboardingService()

    /// 当前引导版本 — 改大此值会让所有用户重新看一次新引导
    static let currentVersion: Int = 1

    private static let key = "RM.onboarding.shownVersion"

    @Published private(set) var needsToShow: Bool

    private init() {
        let shown = UserDefaults.standard.integer(forKey: Self.key)
        self.needsToShow = shown < Self.currentVersion
    }

    /// 用户完成或跳过引导
    func markCompleted() {
        UserDefaults.standard.set(Self.currentVersion, forKey: Self.key)
        needsToShow = false
    }

    /// 调试：重置引导
    func reset() {
        UserDefaults.standard.removeObject(forKey: Self.key)
        needsToShow = true
    }
}
