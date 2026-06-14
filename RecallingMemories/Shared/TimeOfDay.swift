//
//  TimeOfDay.swift
//  拾忆
//
//  根据小时数把一天分成 7 段时辰 —— 给 UI 提供"时间感"语义
//
//  使用场景：
//   - 引导页第一页根据时辰显示「深夜的此刻 / 清晨的此刻 / …」
//   - SpacetimeAnchor 已有自己的版本（粒度相同，先保留独立避免破坏现有行为）
//

import Foundation
import SwiftUI

enum TimeOfDay: String, CaseIterable {
    case lateNight     // 0-5  深夜
    case earlyMorning  // 5-8  清晨
    case morning       // 8-11 上午
    case noon          // 11-14 正午
    case afternoon     // 14-17 午后
    case dusk          // 17-19 黄昏
    case evening       // 19-22 夜晚
    // 22-24 归为 lateNight，与 0-5 共用同一段，避免"夜晚 22:00"和"深夜 22:30"的边界混乱

    static func now(date: Date = Date(), calendar: Calendar = .current) -> TimeOfDay {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 0..<5:   return .lateNight
        case 5..<8:   return .earlyMorning
        case 8..<11:  return .morning
        case 11..<14: return .noon
        case 14..<17: return .afternoon
        case 17..<19: return .dusk
        case 19..<22: return .evening
        default:      return .lateNight  // 22-24
        }
    }

    /// 中文名称（独立用，比如"夜晚"）
    var chineseName: String {
        switch self {
        case .lateNight:    return "深夜"
        case .earlyMorning: return "清晨"
        case .morning:      return "上午"
        case .noon:         return "正午"
        case .afternoon:    return "午后"
        case .dusk:         return "黄昏"
        case .evening:      return "夜晚"
        }
    }

    /// 引导页"x 的此刻"格式
    var greeting: String {
        "\(chineseName)的此刻"
    }

    /// 配色 —— 与时辰对应的暖度
    var tint: Color {
        switch self {
        case .lateNight:    return Color(red: 0.55, green: 0.55, blue: 0.95)  // 深蓝紫
        case .earlyMorning: return Color(red: 1.00, green: 0.80, blue: 0.65)  // 朝阳橙
        case .morning:      return Color(red: 1.00, green: 0.90, blue: 0.55)  // 暖黄
        case .noon:         return Color(red: 1.00, green: 0.85, blue: 0.55)  // 默认暖
        case .afternoon:    return Color(red: 1.00, green: 0.78, blue: 0.50)  // 偏橘
        case .dusk:         return Color(red: 1.00, green: 0.55, blue: 0.55)  // 暮色红
        case .evening:      return Color(red: 0.65, green: 0.60, blue: 0.95)  // 紫蓝
        }
    }
}
