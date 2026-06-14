//
//  NotificationSettingsView.swift
//  拾忆
//
//  「那年今日」推送设置 — 启用开关 + 提醒时间 + 权限状态
//

import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var service = NotificationService.shared
    @Query(sort: \Memory.createdAt, order: .reverse) private var allMemories: [Memory]

    @State private var dailyTime: Date = NotificationSettingsView.makeTime(hour: 9)

    var body: some View {
        Form {
            Section {
                Toggle("「那年今日」回忆推送", isOn: Binding(
                    get: { service.onThisDayEnabled },
                    set: { newValue in
                        service.onThisDayEnabled = newValue
                        if newValue {
                            Task { await ensureAuthAndReschedule() }
                        } else {
                            Task { await service.reschedule(using: allMemories) }
                        }
                    }
                ))

                if service.onThisDayEnabled {
                    DatePicker("提醒时间",
                               selection: $dailyTime,
                               displayedComponents: .hourAndMinute)
                        .onChange(of: dailyTime) { _, newValue in
                            let hour = Calendar.current.component(.hour, from: newValue)
                            service.dailyHour = hour
                            Task { await service.reschedule(using: allMemories) }
                        }
                }
            } footer: {
                Text("每天定点扫描历史上的同月同日，把你过去写下的想法重新带回来。所有计算都在本地完成。")
            }

            Section("权限") {
                HStack {
                    Image(systemName: authIcon)
                        .foregroundStyle(authColor)
                    Text(authText)
                    Spacer()
                    if service.authorizationStatus == .denied {
                        Button("去设置") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.caption)
                    }
                }
            }

            Section("调试") {
                Button {
                    Task { await service.reschedule(using: allMemories) }
                } label: {
                    Label("立即重新排程", systemImage: "arrow.clockwise")
                }
            }
        }
        .navigationTitle("通知")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            dailyTime = Self.makeTime(hour: service.dailyHour)
            await service.refreshAuthorizationStatus()
        }
    }

    private func ensureAuthAndReschedule() async {
        if service.authorizationStatus != .authorized {
            _ = await service.requestAuthorization()
        }
        await service.reschedule(using: allMemories)
    }

    // MARK: - 权限文案

    private var authIcon: String {
        switch service.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "checkmark.circle.fill"
        case .denied: return "xmark.octagon.fill"
        default: return "questionmark.circle.fill"
        }
    }

    private var authColor: Color {
        switch service.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        default: return .secondary
        }
    }

    private var authText: String {
        switch service.authorizationStatus {
        case .authorized:    return "已授权"
        case .provisional:   return "已临时授权"
        case .ephemeral:     return "App Clip 授权"
        case .denied:        return "已拒绝 — 推送将不会送达"
        case .notDetermined: return "尚未请求"
        @unknown default:    return "未知状态"
        }
    }

    /// 用「今天 09:00」生成一个 Date 给 DatePicker 用
    static func makeTime(hour: Int) -> Date {
        let cal = Calendar.current
        let now = Date()
        var components = cal.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = 0
        return cal.date(from: components) ?? now
    }
}

#Preview {
    NavigationStack { NotificationSettingsView() }
        .modelContainer(for: [Memory.self, Person.self], inMemory: true)
}
