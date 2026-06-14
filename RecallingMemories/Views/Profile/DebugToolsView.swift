//
//  DebugToolsView.swift
//  拾忆
//
//  调试工具集 —— 所有"开发期需要、用户日常用不上"的操作集中在这里
//
//  入口隐藏：在「我的 → 关于 → 关于拾忆 → 版本号连点 7 次」解锁
//  随时可关：本页底部「关闭调试模式」按钮
//

import SwiftUI
import SwiftData
import UserNotifications
import WidgetKit

struct DebugToolsView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var easterEgg = EasterEggService.shared

    @State private var lastActionResult: String?
    @State private var showLockConfirm = false

    /// 数据计数 —— 计算属性，每次 body 重算（数据量小可接受）
    private var memoryCount: Int {
        (try? modelContext.fetchCount(FetchDescriptor<Memory>())) ?? 0
    }
    private var personCount: Int {
        (try? modelContext.fetchCount(FetchDescriptor<Person>())) ?? 0
    }
    private var attachmentCount: Int {
        (try? modelContext.fetchCount(FetchDescriptor<Attachment>())) ?? 0
    }

    var body: some View {
        Form {
            Section {
                bannerHeader
            }

            Section("引导与新手") {
                actionRow(
                    title: "重置首屏引导",
                    icon: "questionmark.circle",
                    description: "下次启动会重新出现 4 页引导"
                ) {
                    OnboardingService.shared.reset()
                    return "已重置 — 下次启动看引导"
                }
            }

            Section("通知") {
                actionRow(
                    title: "立即重排「那年今日」",
                    icon: "bell.badge",
                    description: "用最新数据扫描接下来 30 天"
                ) {
                    let descriptor = FetchDescriptor<Memory>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
                    let memories = (try? modelContext.fetch(descriptor)) ?? []
                    await NotificationService.shared.refreshAuthorizationStatus()
                    await NotificationService.shared.reschedule(using: memories)
                    let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
                    return "已排程，当前待发推送 \(pending.count) 条"
                }

                actionRow(
                    title: "清除全部待发推送",
                    icon: "bell.slash",
                    description: "包括非「那年今日」的所有待发通知",
                    role: .destructive
                ) {
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    return "已清除全部待发推送"
                }
            }

            Section("Widget") {
                actionRow(
                    title: "强制刷新桌面 Widget",
                    icon: "rectangle.stack.badge.plus",
                    description: "重新生成快照并通知 WidgetCenter"
                ) {
                    WidgetSnapshotPublisher.publish(modelContainer: modelContext.container)
                    return "Widget 快照已刷新"
                }

                actionRow(
                    title: "查看快照内容",
                    icon: "doc.text.magnifyingglass",
                    description: "读取 App Group 中的 WidgetSnapshot 摘要"
                ) {
                    let snapshot = WidgetSnapshotStore.load()
                    return """
                    总数 \(snapshot.totalCount)
                    最近 \(snapshot.latest?.text.prefix(20) ?? "无")
                    那年今日 \(snapshot.onThisDay?.text.prefix(20) ?? "无")
                    """
                }
            }

            Section("云同步") {
                infoRow(
                    label: "iCloud 同步",
                    value: CloudSyncService.shared.isEnabled ? "已启用" : "未启用"
                )
                infoRow(
                    label: "图片附件同步",
                    value: CloudSyncService.shared.includeMedia ? "已启用" : "未启用"
                )
                infoRow(
                    label: "iCloud 账号",
                    value: CloudSyncService.shared.accountStatusDescription
                )
                actionRow(
                    title: "刷新 iCloud 账号状态",
                    icon: "arrow.clockwise.icloud",
                    description: nil
                ) {
                    await CloudSyncService.shared.refreshAccountStatus()
                    return "状态已刷新：\(CloudSyncService.shared.accountStatusDescription)"
                }
            }

            Section("彩蛋") {
                infoRow(
                    label: "彩蛋已发现",
                    value: easterEgg.isEggUnlocked ? "是 ✓" : "否"
                )
                if easterEgg.isEggUnlocked {
                    actionRow(
                        title: "重置彩蛋（让它重新可发现）",
                        icon: "sparkles",
                        description: nil,
                        role: .destructive
                    ) {
                        easterEgg.lockEgg()
                        return "已重置 — 关于页 logo 角标会消失"
                    }
                }
            }

            Section("数据快照") {
                infoRow(label: "Memory 总数", value: "\(memoryCount)")
                infoRow(label: "Person 总数", value: "\(personCount)")
                infoRow(label: "Attachment 总数", value: "\(attachmentCount)")
                infoRow(label: "App 版本", value: AppInfo.fullVersion)
            }

            Section {
                Button {
                    showLockConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("关闭调试模式")
                        Spacer()
                    }
                }
                .foregroundStyle(.red)
            } footer: {
                Text("关闭后，「我的」中不会再显示「调试工具」入口。再次解锁需要在关于页连点版本号 7 次。")
            }
        }
        .navigationTitle("调试工具")
        .navigationBarTitleDisplayMode(.inline)
        .alert("关闭调试模式？", isPresented: $showLockConfirm) {
            Button("关闭", role: .destructive) {
                easterEgg.lockDebug()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("入口将从「我的」消失。下次需要时连点关于页版本号 7 次重新解锁。")
        }
        .overlay(alignment: .bottom) {
            if let result = lastActionResult {
                resultToast(result)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: lastActionResult)
    }

    // MARK: - 顶部说明 banner

    private var bannerHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("调试工具")
                    .font(.subheadline.bold())
                Text("这里的操作通常用于开发或排查问题。如果你不知道某项是干什么的，跳过即可。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 行组件

    /// 信息行（只读）
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    /// 操作行（可点）
    private func actionRow(
        title: String,
        icon: String,
        description: String?,
        role: ButtonRole? = nil,
        action: @escaping () async -> String
    ) -> some View {
        Button(role: role) {
            Task {
                let result = await action()
                await showResult(result)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(role == .destructive ? .red : .tint)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                    if let description {
                        Text(description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - 结果反馈

    private func resultToast(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
            .padding(.bottom, 24)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @MainActor
    private func showResult(_ text: String) async {
        lastActionResult = text
        try? await Task.sleep(for: .seconds(2.5))
        lastActionResult = nil
    }
}

#Preview {
    NavigationStack { DebugToolsView() }
        .modelContainer(for: [Memory.self, Person.self, Attachment.self], inMemory: true)
}
