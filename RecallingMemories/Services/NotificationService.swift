//
//  NotificationService.swift
//  拾忆
//
//  本地推送服务 — 「那年今日」每天定点扫描历史同日记忆并提醒
//

import Foundation
import UserNotifications
import SwiftData

@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    /// 通知分类：用于点击跳转到详情
    static let onThisDayCategory = "ON_THIS_DAY"
    /// userInfo 中携带的 Memory.id
    static let memoryIDKey = "memoryID"

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// 每日提醒触发时间（小时） — 默认 09:00
    @Published var dailyHour: Int = 9 {
        didSet { saveSettings() }
    }
    /// 是否启用「那年今日」
    @Published var onThisDayEnabled: Bool {
        didSet { saveSettings() }
    }

    private let defaults = UserDefaults.standard
    private static let hourKey = "RM.notification.onThisDay.hour"
    private static let enabledKey = "RM.notification.onThisDay.enabled"

    override init() {
        // 读取持久化设置（用 static key 避免在 super.init 前访问实例成员）
        let savedHour = UserDefaults.standard.object(forKey: Self.hourKey) as? Int
        self.dailyHour = savedHour ?? 9
        self.onThisDayEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerCategory()
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - 权限

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
    }

    // MARK: - 设置持久化

    private func saveSettings() {
        defaults.set(dailyHour, forKey: Self.hourKey)
        defaults.set(onThisDayEnabled, forKey: Self.enabledKey)
    }

    // MARK: - 注册类别（带「查看」action）

    private func registerCategory() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW",
            title: "看看",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: Self.onThisDayCategory,
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - 「那年今日」扫描与排程

    /// 扫描历史记忆，为接下来 30 天内每天有「那年今日」内容的日期排程
    /// 每次调用会清除并重排，保证设置变更后即时生效
    func reschedule(using memories: [Memory], lookaheadDays: Int = 30) async {
        let center = UNUserNotificationCenter.current()
        // 清除旧的「那年今日」请求
        let pending = await center.pendingNotificationRequests()
        let oldIDs = pending
            .filter { $0.identifier.hasPrefix("onThisDay-") }
            .map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: oldIDs)

        guard onThisDayEnabled, authorizationStatus == .authorized else { return }

        let cal = Calendar.current
        let now = Date()

        for offset in 0..<lookaheadDays {
            guard let day = cal.date(byAdding: .day, value: offset, to: now) else { continue }
            let matches = OnThisDayMatcher.match(memories, against: day)
            guard let representative = matches.first else { continue }

            // 触发时间：当日 dailyHour:00
            var components = cal.dateComponents([.year, .month, .day], from: day)
            components.hour = dailyHour
            components.minute = 0
            // 如果当天目标时间已过，跳过（offset == 0 且时间过了）
            if let trigger = cal.date(from: components), trigger < now { continue }

            let yearsAgo = cal.dateComponents([.year], from: representative.createdAt, to: day).year ?? 0
            let body = makeNotificationBody(memory: representative, totalCount: matches.count, yearsAgo: yearsAgo)

            let content = UNMutableNotificationContent()
            content.title = "那年今日"
            content.body = body
            content.sound = .default
            content.categoryIdentifier = Self.onThisDayCategory
            content.userInfo = [Self.memoryIDKey: representative.id.uuidString]

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "onThisDay-\(components.year!)-\(components.month!)-\(components.day!)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    private func makeNotificationBody(memory: Memory, totalCount: Int, yearsAgo: Int) -> String {
        let prefix: String
        if yearsAgo >= 1 {
            prefix = "\(yearsAgo) 年前的今天"
        } else {
            // 不到 1 年，按月计算
            let months = Calendar.current.dateComponents([.month], from: memory.createdAt, to: Date()).month ?? 0
            prefix = months >= 1 ? "\(months) 个月前的今天" : "今天的回忆"
        }

        var body = "\(prefix)，"
        if !memory.text.isEmpty {
            let preview = memory.text.prefix(40)
            body += "你写下：「\(preview)\(memory.text.count > 40 ? "…" : "")」"
        } else if let location = memory.locationName {
            body += "你曾在 \(location)"
        } else {
            body += "你留下了一段记忆"
        }

        if totalCount > 1 {
            body += "（共 \(totalCount) 条）"
        }
        return body
    }
}

// MARK: - 前台展示 + 点击处理

extension NotificationService: UNUserNotificationCenterDelegate {
    /// 应用在前台时也展示通知
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    /// 用户点击通知 → 转发给 AppRouter 完成跳转
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let idString = userInfo[Self.memoryIDKey] as? String,
              let id = UUID(uuidString: idString) else { return }
        await AppRouter.shared.openMemory(id: id)
    }
}
