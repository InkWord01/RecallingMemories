//
//  EasterEggService.swift
//  拾忆
//
//  彩蛋与调试入口状态管理
//
//  两层设计：
//   - egg：用户连点 logo 5 次解锁，主要是"被看见"的感谢仪式
//   - debug：开发者连点版本号 7 次解锁，集中所有维护操作；可一键关闭恢复正常
//

import Foundation
import SwiftUI

@MainActor
final class EasterEggService: ObservableObject {
    static let shared = EasterEggService()

    private static let eggKey = "RM.easterEgg.unlocked"
    private static let debugKey = "RM.debug.unlocked"

    /// 用户是否已经发现过彩蛋（持久化，看过一次就一直显示彩蛋徽章）
    @Published private(set) var isEggUnlocked: Bool

    /// 调试模式是否启用
    @Published private(set) var isDebugUnlocked: Bool

    private init() {
        self.isEggUnlocked = UserDefaults.standard.bool(forKey: Self.eggKey)
        self.isDebugUnlocked = UserDefaults.standard.bool(forKey: Self.debugKey)
    }

    func unlockEgg() {
        guard !isEggUnlocked else { return }
        UserDefaults.standard.set(true, forKey: Self.eggKey)
        isEggUnlocked = true
    }

    /// 重置彩蛋 —— 让它重新可被发现（调试用）
    func lockEgg() {
        UserDefaults.standard.set(false, forKey: Self.eggKey)
        isEggUnlocked = false
    }

    func unlockDebug() {
        guard !isDebugUnlocked else { return }
        UserDefaults.standard.set(true, forKey: Self.debugKey)
        isDebugUnlocked = true
    }

    /// 关闭调试入口（在 DebugView 里给用户一个出口）
    func lockDebug() {
        UserDefaults.standard.set(false, forKey: Self.debugKey)
        isDebugUnlocked = false
    }
}
