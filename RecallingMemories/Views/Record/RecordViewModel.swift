//
//  RecordViewModel.swift
//  拾忆
//

import Foundation
import SwiftUI

/// 时空锚点（自动捕获的时间 + 位置 + 天气 + 情绪）
struct SpacetimeAnchor: Equatable {
    var timestamp: Date
    var locationName: String?
    var coordinate: (lat: Double, lon: Double)?
    var weatherIcon: String?
    var moodTag: String?

    /// 「深夜 / 清晨 / 午后…」感性描述
    var timeDescription: String {
        let hour = Calendar.current.component(.hour, from: timestamp)
        switch hour {
        case 0..<5:   return "深夜"
        case 5..<8:   return "清晨"
        case 8..<11:  return "上午"
        case 11..<14: return "正午"
        case 14..<17: return "午后"
        case 17..<19: return "黄昏"
        case 19..<22: return "夜晚"
        default:      return "深夜"
        }
    }

    static func == (lhs: SpacetimeAnchor, rhs: SpacetimeAnchor) -> Bool {
        lhs.timestamp == rhs.timestamp
            && lhs.locationName == rhs.locationName
            && lhs.weatherIcon == rhs.weatherIcon
            && lhs.moodTag == rhs.moodTag
    }
}

@MainActor
final class RecordViewModel: ObservableObject {

    @Published var draftText: String = ""
    @Published var attachments: [Attachment] = []
    @Published var spacetimeAnchor: SpacetimeAnchor?

    /// 捕获当前时空锚点（时间 + 位置 + 天气）
    func captureSpacetimeAnchor() {
        // TODO: 接入 LocationService / WeatherService
        spacetimeAnchor = SpacetimeAnchor(
            timestamp: Date(),
            locationName: nil,
            coordinate: nil,
            weatherIcon: nil,
            moodTag: nil
        )
    }

    func openCamera() {
        // TODO: 调用 PhotosUI / AVFoundation
    }

    func openPhotoLibrary() {
        // TODO: PHPickerViewController
    }

    func startVoiceCapture() {
        // TODO: Speech Framework
    }

    func tagPeople() {
        // TODO: 通讯录或自定义标签
    }

    func save() {
        // TODO: 通过 SwiftData modelContext 持久化
        print("保存记录：\(draftText)")
        draftText = ""
        attachments = []
    }
}
