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

    /// 是否要求记录页自动聚焦输入框 + 重新捕获时空锚点（来自 Widget 「快速记录」）
    @Published var requestQuickRecordFocus: Bool = false

    func openMemory(id: UUID) {
        // 切回时光 Tab，让详情自然出现在该上下文里
        requestedTab = .timeline
        pendingMemoryID = id
    }

    /// 解析外部 URL —— Widget / 通知 / 微信回跳等
    /// 支持的 scheme：
    ///   recallingmemories://record               → 切到记录页 + 聚焦输入框
    ///   recallingmemories://on-this-day          → 切到我的 Tab → 那年今日（暂仍切到时光 + 弹今天匹配）
    ///   recallingmemories://memory/<UUID>        → 弹出该条详情
    func handle(url: URL) {
        guard url.scheme == WidgetShared.urlScheme else { return }

        // host 形式与 path 形式都允许
        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "record":
            requestedTab = .record
            requestQuickRecordFocus = true

        case "on-this-day":
            // 暂归到「我的」Tab；具体打开 OnThisDayView 由 ProfileView 内决定
            requestedTab = .profile

        case "memory":
            if let idString = pathComponents.first,
               let id = UUID(uuidString: idString) {
                openMemory(id: id)
            }

        default:
            break
        }
    }
}
