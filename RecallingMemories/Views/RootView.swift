//
//  RootView.swift
//  拾忆
//
//  根视图 — 切换：记录 / 时间轴 / 地图 / 我的
//

import SwiftUI
import SwiftData

struct RootView: View {
    @ObservedObject private var router = AppRouter.shared
    @ObservedObject private var onboarding = OnboardingService.shared
    @Query(sort: \Memory.createdAt, order: .reverse) private var allMemories: [Memory]

    @State private var selectedTab: Tab = .record
    @State private var pendingMemory: Memory?

    enum Tab: Hashable {
        case record, timeline, map, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordView()
                .tabItem { Label("记录", systemImage: "square.and.pencil") }
                .tag(Tab.record)

            TimelineView()
                .tabItem { Label("时光", systemImage: "list.bullet.rectangle") }
                .tag(Tab.timeline)

            MapView()
                .tabItem { Label("足迹", systemImage: "map") }
                .tag(Tab.map)

            ProfileView()
                .tabItem { Label("我的", systemImage: "person.circle") }
                .tag(Tab.profile)
        }
        .tint(.white)
        // 路由：通知 / 小组件等外部入口
        // 引导期间挂起路由请求，避免被 fullScreenCover 盖住
        .onChange(of: router.requestedTab) { _, requested in
            guard let requested, !onboarding.needsToShow else { return }
            selectedTab = requested
            router.requestedTab = nil
        }
        .onChange(of: router.pendingMemoryID) { _, id in
            guard let id, !onboarding.needsToShow else { return }
            pendingMemory = allMemories.first { $0.id == id }
            router.pendingMemoryID = nil
        }
        // 引导刚完成时，若有挂起的路由请求，再处理一次
        .onChange(of: onboarding.needsToShow) { _, needsToShow in
            guard !needsToShow else { return }
            if let requested = router.requestedTab {
                selectedTab = requested
                router.requestedTab = nil
            }
            if let id = router.pendingMemoryID {
                pendingMemory = allMemories.first { $0.id == id }
                router.pendingMemoryID = nil
            }
        }
        .onOpenURL { url in
            // 优先尝试微信回调；如未匹配再走应用自定义深链
            if !WeChatService.shared.handleOpenURL(url) {
                router.handle(url: url)
            }
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            WeChatService.shared.handleUniversalLink(activity)
        }
        .sheet(item: $pendingMemory) { memory in
            MemoryDetailView(memory: memory)
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: Binding(
            get: { onboarding.needsToShow },
            set: { if !$0 { onboarding.markCompleted() } }
        )) {
            OnboardingView(onFinish: { onboarding.markCompleted() })
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Memory.self, Person.self], inMemory: true)
}
