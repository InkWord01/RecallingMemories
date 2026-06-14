//
//  RecallingMemoriesApp.swift
//  拾忆 — 基于时空的灵感与记忆捕捉工具
//
//  App 主入口
//

import SwiftUI
import SwiftData

@main
struct RecallingMemoriesApp: App {

    /// 全局 SwiftData 模型容器
    let modelContainer: ModelContainer

    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            modelContainer = try ModelContainer(
                for: Memory.self, Person.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("初始化 SwiftData ModelContainer 失败：\(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark) // 设计理念：深色模式优先
                .task {
                    await rescheduleOnThisDayNotifications()
                }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, phase in
            // 回到前台时重排，覆盖「跨天」「设置变更后台」等场景
            if phase == .active {
                Task { await rescheduleOnThisDayNotifications() }
            }
        }
    }

    /// 用最新数据重排「那年今日」通知
    @MainActor
    private func rescheduleOnThisDayNotifications() async {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Memory>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        guard let memories = try? context.fetch(descriptor) else { return }
        await NotificationService.shared.refreshAuthorizationStatus()
        await NotificationService.shared.reschedule(using: memories)
    }
}
