//
//  AppRouter.swift
//  拾忆
//
//  全局路由 — 让通知 / 小组件 / URL Scheme 等外部入口能跳转到 Memory 详情
//

import Foundation
import Combine

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    /// 等待打开的 Memory.id；RootView 监听这个值并 push 详情
    @Published var pendingMemoryID: UUID?

    /// 期望切换到的 Tab（来自外部入口）
    @Published var requestedTab: RootView.Tab?

    func openMemory(id: UUID) {
        // 切回时光 Tab，让详情自然出现在该上下文里
        requestedTab = .timeline
        pendingMemoryID = id
    }
}
