//
//  CloudSyncService.swift
//  拾忆
//
//  云同步配置 — 选择本地 / iCloud private database 模式构建 ModelContainer
//
//  - MVP 默认本地存储（init.txt 隐私策略）
//  - 用户在「我的 → 云同步」明确开启 + 同意隐私条款后切换到 CloudKit
//  - 切换需重启 App 才能让 ModelContainer 用新配置生效（这是 SwiftData 的限制）
//

import Foundation
import SwiftData
import CloudKit

@MainActor
final class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()

    /// CloudKit 容器标识 — 必须与 entitlements 中一致
    static let cloudKitContainerID = "iCloud.com.recallingmemories.app"

    /// 用户偏好 key
    private static let enabledKey = "RM.cloudSync.enabled"
    private static let agreementKey = "RM.cloudSync.agreedAt"
    private static let mediaKey = "RM.cloudSync.includeMedia"

    /// 当前是否启用 — 只读自 UserDefaults
    @Published private(set) var isEnabled: Bool

    /// 是否同步媒体附件（图片）—— 默认关闭（耗流量）
    @Published private(set) var includeMedia: Bool

    /// iCloud 账号状态
    @Published private(set) var accountStatus: CKAccountStatus = .couldNotDetermine

    /// 是否已签署同意隐私条款
    var hasAgreed: Bool {
        UserDefaults.standard.object(forKey: Self.agreementKey) != nil
    }

    /// 同意时间
    var agreedAt: Date? {
        UserDefaults.standard.object(forKey: Self.agreementKey) as? Date
    }

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        self.includeMedia = UserDefaults.standard.bool(forKey: Self.mediaKey)
        Task { await refreshAccountStatus() }
    }

    // MARK: - 偏好读写

    /// 用户在 UI 中切换开关时调用 — 持久化偏好但不立即重建 container
    /// 提示用户重启 App 后生效
    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Self.enabledKey)
        isEnabled = enabled
    }

    /// 切换是否同步媒体附件 —— 不需要重启 App，下次保存的附件就生效
    func setIncludeMedia(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Self.mediaKey)
        includeMedia = value
    }

    /// 用户同意隐私条款
    func recordAgreement() {
        UserDefaults.standard.set(Date(), forKey: Self.agreementKey)
        objectWillChange.send()
    }

    /// 撤回同意（用户撤回授权时调用）
    func revokeAgreement() {
        UserDefaults.standard.removeObject(forKey: Self.agreementKey)
        setEnabled(false)
    }

    // MARK: - 账号状态

    /// 查询当前 iCloud 登录状态
    func refreshAccountStatus() async {
        do {
            let status = try await CKContainer(identifier: Self.cloudKitContainerID).accountStatus()
            self.accountStatus = status
        } catch {
            self.accountStatus = .couldNotDetermine
        }
    }

    var accountStatusDescription: String {
        switch accountStatus {
        case .available:        return "已登录 iCloud"
        case .noAccount:        return "未登录 iCloud — 请在系统设置中登录"
        case .restricted:       return "iCloud 账号受限"
        case .temporarilyUnavailable: return "iCloud 暂时不可用，稍后再试"
        case .couldNotDetermine: return "无法获取 iCloud 状态"
        @unknown default:       return "未知"
        }
    }

    // MARK: - 构建 ModelContainer

    /// App 启动时调用，根据用户偏好构建对应模式的 ModelContainer
    /// - 本地模式：默认存储；
    /// - 云模式：cloudKitDatabase = .private，Schema 会同步到 iCloud Private DB
    static func makeModelContainer() throws -> ModelContainer {
        let enabled = UserDefaults.standard.bool(forKey: enabledKey)
        let agreed = UserDefaults.standard.object(forKey: agreementKey) != nil

        let schema = Schema([Memory.self, Person.self, Attachment.self])
        let configuration: ModelConfiguration

        if enabled && agreed {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(cloudKitContainerID)
            )
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        }

        return try ModelContainer(for: schema, configurations: configuration)
    }
}
