//
//  ProfileView.swift
//  拾忆
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject private var weChat = WeChatService.shared
    @State private var loginErrorMessage: String?
    @State private var loginToast: String?

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
                    if let code = weChat.lastAuthCode {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("已通过微信授权")
                                    .font(.subheadline)
                                Text("code: \(code.prefix(12))…")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("登出") { weChatLogout() }
                                .font(.caption)
                        }
                    } else {
                        Button {
                            Task { await weChatLogin() }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "message.fill")
                                    .foregroundStyle(.green)
                                Text("微信登录")
                                Spacer()
                                if !weChat.isWeChatInstalled {
                                    Text("未安装")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("偏好") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("通知与推送", systemImage: "bell.badge")
                    }
                    NavigationLink {
                        PeopleManagementView()
                    } label: {
                        Label("人物管理", systemImage: "person.2.crop.square.stack")
                    }
                }

                Section("数据") {
                    NavigationLink {
                        CloudSyncSettingsView()
                    } label: {
                        Label("云同步设置", systemImage: "icloud")
                    }
                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("数据导出", systemImage: "square.and.arrow.up.on.square")
                    }
                }

                Section("关于") {
                    NavigationLink {
                        HelpCenterView()
                    } label: {
                        Label("帮助中心", systemImage: "questionmark.bubble.fill")
                    }
                    NavigationLink {
                        LegalDocumentView(document: LegalDocuments.privacy)
                    } label: {
                        Label("隐私协议", systemImage: "hand.raised.fill")
                    }
                    NavigationLink {
                        LegalDocumentView(document: LegalDocuments.terms)
                    } label: {
                        Label("用户协议", systemImage: "doc.text.fill")
                    }
                    NavigationLink {
                        LegalDocumentView(document: LegalDocuments.acknowledgements)
                    } label: {
                        Label("第三方致谢", systemImage: "heart.text.square")
                    }
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("0.1.0").foregroundStyle(.secondary)
                    }
                    Button {
                        OnboardingService.shared.reset()
                    } label: {
                        Label("重新查看引导", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("我的")
            .alert("微信登录失败", isPresented: Binding(
                get: { loginErrorMessage != nil },
                set: { if !$0 { loginErrorMessage = nil } }
            ), presenting: loginErrorMessage) { _ in
                Button("好") { loginErrorMessage = nil }
            } message: { msg in
                Text(msg)
            }
            .overlay(alignment: .top) {
                if let toast = loginToast {
                    Text(toast)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThickMaterial, in: Capsule())
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - 微信登录

    private func weChatLogin() async {
        do {
            let code = try await weChat.authLogin()
            // 实际项目里：把 code 发给后端换 access_token / openid，本地仅展示
            await showToast("已授权，code 已就绪")
            _ = code
        } catch {
            loginErrorMessage = error.localizedDescription
        }
    }

    private func weChatLogout() {
        weChat.signOut()
        Task { await showToast("已登出") }
    }

    @MainActor
    private func showToast(_ text: String) async {
        withAnimation { loginToast = text }
        try? await Task.sleep(for: .seconds(1.5))
        withAnimation { loginToast = nil }
    }
}

#Preview {
    ProfileView()
}
