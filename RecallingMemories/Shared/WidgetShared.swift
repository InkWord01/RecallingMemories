//
//  WidgetSharedConstants.swift
//  拾忆 / RecallingMemoriesWidget
//
//  主 App 与 Widget 共享的常量
//

import Foundation

enum WidgetShared {
    /// App Group ID — 主 App 与 Widget Extension 共享数据
    static let appGroup = "group.com.recallingmemories.app"

    /// 主 App 自定义 URL Scheme — Widget 点击跳转入口
    static let urlScheme = "recallingmemories"

    /// Widget → 主 App 的深链
    enum DeepLink {
        /// 触发记录页（启动即弹键盘）
        static let record = URL(string: "\(urlScheme)://record")!
        /// 跳转到「那年今日」
        static let onThisDay = URL(string: "\(urlScheme)://on-this-day")!

        /// 跳转到指定 Memory 详情
        static func memory(_ id: UUID) -> URL {
            URL(string: "\(urlScheme)://memory/\(id.uuidString)")!
        }
    }

    /// UserDefaults key — Widget 用来读取最近的快照数据
    enum DefaultsKey {
        static let snapshot = "RM.widget.snapshot"
    }
}
