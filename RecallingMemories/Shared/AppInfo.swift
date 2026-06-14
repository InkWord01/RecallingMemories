//
//  AppInfo.swift
//  拾忆
//
//  应用元信息中央化 —— 版本号 / 构建号 / 作者 / 版权信息
//
//  设计原则：
//   1. 版本号优先从 Info.plist 读取（CFBundleShortVersionString / CFBundleVersion）
//   2. Info.plist 缺失时用编译期 fallback，保证 Preview 等场景不显示空白
//   3. 任何想显示版本/作者的地方，统一来这里取，避免散落在多处
//

import Foundation

enum AppInfo {

    /// 应用名称（显示用）
    static let displayName = "拾忆"

    /// 英文标识
    static let englishName = "RecallingMemories"

    /// 作者
    static let author = "zizhi（字之）"

    /// 起始年份（用于版权声明）
    static let copyrightStartYear = 2026

    /// 营销版本号 — 形如 "0.1.0"
    static var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

    /// 构建号 — 形如 "1"
    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    /// 完整版本字符串：营销版本 + 构建号
    /// - 例：`0.1.0 (1)` 或 release 时只显示 `0.1.0`
    static var fullVersion: String {
        "\(marketingVersion) (\(buildNumber))"
    }

    /// 版权声明 — 自动追到当前年份
    static var copyright: String {
        let currentYear = Calendar.current.component(.year, from: Date())
        if currentYear > copyrightStartYear {
            return "© \(copyrightStartYear)–\(currentYear) \(author)"
        }
        return "© \(copyrightStartYear) \(author)"
    }
}
