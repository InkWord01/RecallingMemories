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
            modelContainer = try CloudSyncService.makeModelContainer()
        } catch {
            fatalError("初始化 SwiftData ModelContainer 失败：\(error)")
        }
        // 注册微信 SDK（无 SDK 集成时为 no-op）
        WeChatService.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark) // 设计理念：深色模式优先
                .task {
                    await rescheduleOnThisDayNotifications()
                    WidgetSnapshotPublisher.publish(modelContainer: modelContainer)
                }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, phase in
            // 回到前台时重排 + 发布最新快照
            if phase == .active {
                Task {
                    await rescheduleOnThisDayNotifications()
                    WidgetSnapshotPublisher.publish(modelContainer: modelContainer)
                }
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
