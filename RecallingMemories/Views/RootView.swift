//
//  RootView.swift
//  拾忆
//
//  根视图 — 切换：记录 / 时间轴 / 地图 / 我的
//

import SwiftUI

struct RootView: View {
    @State private var selectedTab: Tab = .record

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
    }
}

#Preview {
    RootView()
}
