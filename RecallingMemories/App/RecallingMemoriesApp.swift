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
        }
        .modelContainer(modelContainer)
    }
}
