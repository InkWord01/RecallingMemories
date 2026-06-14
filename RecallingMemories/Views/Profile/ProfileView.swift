//
//  ProfileView.swift
//  拾忆
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("回忆") {
                    NavigationLink {
                        OnThisDayView()
                    } label: {
                        Label("那年今日", systemImage: "calendar.badge.clock")
                    }
                }

                Section("账号") {
                    Button("微信登录") {
                        // TODO: WXApi.sendAuthReq
                    }
                }

                Section("偏好") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("通知与推送", systemImage: "bell.badge")
                    }
                }

                Section("数据") {
                    NavigationLink("云同步设置") { Text("云同步（Pro）") }
                    NavigationLink("数据导出") { Text("导出 PDF / Markdown 时光书（Pro）") }
                }

                Section("关于") {
                    NavigationLink("隐私协议") { Text("隐私协议") }
                    NavigationLink("用户协议") { Text("用户协议") }
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("0.1.0").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
}

#Preview {
    ProfileView()
}
