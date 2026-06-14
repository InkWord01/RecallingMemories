//
//  CloudSyncSettingsView.swift
//  拾忆
//
//  云同步设置页 — 默认关闭、明确告知、首次开启需同意隐私条款
//

import SwiftUI
import SwiftData
import CloudKit

struct CloudSyncSettingsView: View {
    @ObservedObject private var service = CloudSyncService.shared
    @State private var showAgreement = false
    @State private var showDisableConfirm = false
    @State private var showRevokeConfirm = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "icloud.fill")
                        .foregroundStyle(service.isEnabled ? .blue : .secondary)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(service.isEnabled ? "iCloud 同步已启用" : "iCloud 同步已关闭")
                            .font(.headline)
                        Text(service.isEnabled
                             ? "你的记忆会自动同步到此 Apple ID 的所有设备"
                             : "你的记忆只保存在本机，不会上云")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            Section {
                Toggle("启用 iCloud 同步", isOn: Binding(
                    get: { service.isEnabled },
                    set: { newValue in
                        if newValue {
                            // 开启 → 先确保已同意条款
                            if service.hasAgreed {
                                service.setEnabled(true)
                            } else {
                                showAgreement = true
                            }
                        } else {
                            // 关闭 → 弹确认（强调云端数据保留）
                            showDisableConfirm = true
                        }
                    }
                ))
            } footer: {
                Text("更改后需重启拾忆才能生效。SwiftData 不支持运行时切换存储模式。")
            }

            // 媒体同步开关 —— 仅在主开关已启用时显示
            if service.isEnabled {
                Section {
                    Toggle("同步图片附件", isOn: Binding(
                        get: { service.includeMedia },
                        set: { service.setIncludeMedia($0) }
                    ))
                } footer: {
                    Text("开启后，新保存的照片会随记忆一起上传到 iCloud（视频暂不上传，体积过大）。已上传的图片可在其它设备自动下载。流量与 iCloud 储存空间由你 Apple ID 计费。")
                }
            }

            // iCloud 账号状态
            Section("iCloud 账号") {
                HStack {
                    Image(systemName: accountStatusIcon)
                        .foregroundStyle(accountStatusColor)
                    Text(service.accountStatusDescription)
                        .font(.subheadline)
                    Spacer()
                    if service.accountStatus == .noAccount {
                        Button("去登录") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.caption)
                    }
                }
                Button {
                    Task { await service.refreshAccountStatus() }
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
            }

            // 隐私条款记录
            if service.hasAgreed {
                Section("隐私授权") {
                    if let agreedAt = service.agreedAt {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("已同意云同步隐私条款")
                                    .font(.subheadline)
                                Text(agreedAt, format: .dateTime.year().month().day().hour().minute())
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button(role: .destructive) {
                        showRevokeConfirm = true
                    } label: {
                        Label("撤回授权", systemImage: "xmark.shield")
                    }
                }
            }

            Section("说明") {
                bullet("数据存储在你的 Apple ID 私有 iCloud 数据库，拾忆服务器看不到。")
                bullet("默认同步范围：文字、时间、地点、人物标签、情绪。")
                bullet("开启「同步图片附件」后，新保存的照片也会随记忆上传；视频暂不上传。")
                bullet("撤回授权或关闭同步：本机数据保留；iCloud 副本继续存在直到你在系统设置「管理 iCloud 储存」中删除。")
            }
            .font(.footnote)
        }
        .navigationTitle("云同步")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await service.refreshAccountStatus()
        }
        .sheet(isPresented: $showAgreement) {
            CloudSyncAgreementSheet(
                onAgree: {
                    service.recordAgreement()
                    service.setEnabled(true)
                    showAgreement = false
                },
                onCancel: { showAgreement = false }
            )
            .presentationDetents([.large])
        }
        .alert("关闭 iCloud 同步？", isPresented: $showDisableConfirm) {
            Button("关闭", role: .destructive) { service.setEnabled(false) }
            Button("取消", role: .cancel) {}
        } message: {
            Text("本机数据会保留。已上传到 iCloud 的副本不会自动删除，可在系统设置 → Apple ID → iCloud → 管理储存空间 中清理。")
        }
        .alert("撤回云同步授权？", isPresented: $showRevokeConfirm) {
            Button("撤回", role: .destructive) {
                service.revokeAgreement()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("撤回后需要重新同意条款才能再次开启同步。")
        }
    }

    // MARK: - 视觉辅助

    private var accountStatusIcon: String {
        switch service.accountStatus {
        case .available:                  return "checkmark.icloud.fill"
        case .noAccount:                  return "xmark.icloud.fill"
        case .restricted:                 return "lock.icloud.fill"
        case .temporarilyUnavailable:     return "exclamationmark.icloud.fill"
        default:                          return "questionmark.circle"
        }
    }

    private var accountStatusColor: Color {
        switch service.accountStatus {
        case .available:                  return .green
        case .noAccount, .restricted:     return .red
        case .temporarilyUnavailable:     return .orange
        default:                          return .secondary
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("·")
            Text(text)
            Spacer()
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - 隐私条款面板

private struct CloudSyncAgreementSheet: View {
    let onAgree: () -> Void
    let onCancel: () -> Void

    @State private var hasReadToBottom = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("云同步隐私须知")
                        .font(.title2.bold())

                    Text("启用 iCloud 同步前请知悉：")
                        .font(.headline)

                    section(
                        title: "数据流向",
                        body: "你的记忆会通过 Apple 提供的 CloudKit 通道传输到你 Apple ID 的 iCloud 私有数据库。拾忆开发者无法访问、读取或导出这些数据。"
                    )
                    section(
                        title: "同步内容",
                        body: "本次只同步：文字、创建时间、地点 POI 名称与坐标、人物标签、情绪标签、自定义标签。"
                    )
                    section(
                        title: "暂不同步",
                        body: "媒体附件（照片 / 视频）仍仅存本机。后续版本会接入 CloudKit Asset 后再行扩展，届时会再次征得你的同意。"
                    )
                    section(
                        title: "网络与流量",
                        body: "同步过程会消耗你的网络流量与 iCloud 储存空间，由 Apple 计费。"
                    )
                    section(
                        title: "撤回与删除",
                        body: "你可以随时关闭同步或撤回授权。已上传到 iCloud 的副本由你掌控：在系统「设置 → Apple ID → iCloud → 管理储存空间 → 拾忆」中可彻底删除。"
                    )
                    section(
                        title: "未成年人",
                        body: "若你尚未成年，请在监护人陪同下做出选择。"
                    )

                    // 底部 anchor — 滚到这里才允许同意
                    Color.clear.frame(height: 1)
                        .onAppear { hasReadToBottom = true }
                }
                .padding()
            }
            .navigationTitle("第一次开启同步")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("不同意") { onCancel() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    if !hasReadToBottom {
                        Text("请滑到底部阅读完整条款")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        onAgree()
                    } label: {
                        Text("我已阅读并同意")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!hasReadToBottom)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
            Text(body)
                .font(.body)
                .foregroundStyle(.primary.opacity(0.85))
                .lineSpacing(3)
        }
    }
}

#Preview {
    NavigationStack { CloudSyncSettingsView() }
}
