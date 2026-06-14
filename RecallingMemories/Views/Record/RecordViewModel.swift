//
//  RecordViewModel.swift
//  拾忆
//
//  极速记录页的视图模型：草稿、时空锚点、媒体附件、语音转写、保存
//

import Foundation
import SwiftUI
import SwiftData
import PhotosUI

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
            && lhs.coordinate?.lat == rhs.coordinate?.lat
            && lhs.coordinate?.lon == rhs.coordinate?.lon
    }
}

/// 媒体处理状态 — 给 RecordView 显示进度提示用
struct MediaProcessingState: Equatable {
    enum Kind {
        case image
        case video
    }

    let kind: Kind
    /// 当前处理到第几个（1-based）
    let current: Int
    /// 总数
    let total: Int

    var label: String {
        let action = kind == .video ? "压缩视频" : "压缩照片"
        return total > 1 ? "\(action) \(current)/\(total)…" : "\(action)…"
    }
}

@MainActor
final class RecordViewModel: ObservableObject {

    @Published var draftText: String = ""
    @Published var attachments: [Attachment] = []
    @Published var spacetimeAnchor: SpacetimeAnchor?

    /// PhotosPicker 选中的项（绑定到 View）
    @Published var pickerItems: [PhotosPickerItem] = []

    /// 已挂载的「和谁在一起」
    @Published var selectedPeople: [Person] = []

    /// 用户从极简情绪标签中选择
    @Published var selectedMood: String?

    /// 是否正在录音转写
    @Published private(set) var isRecording = false

    /// 媒体处理进度 — 选完照片/视频到落盘的过渡态
    @Published private(set) var processingMedia: MediaProcessingState?

    /// 错误提示
    @Published var errorMessage: String?

    /// 极简情绪标签
    let moodOptions: [String] = ["💡顿悟", "🔥激动", "😌平静", "🌙怅然", "🌿温柔"]

    private let speech = SpeechService.shared
    private let location = LocationService.shared

    // MARK: - 时空锚点

    /// 捕获当前时空锚点（时间 + 位置）；位置失败不阻塞，时间永远可用
    func captureSpacetimeAnchor() {
        var anchor = SpacetimeAnchor(timestamp: Date())
        spacetimeAnchor = anchor

        Task {
            do {
                let loc = try await location.requestCurrentLocation()
                anchor.coordinate = (loc.coordinate.latitude, loc.coordinate.longitude)
                if let poi = try? await location.reverseGeocode(loc) {
                    anchor.locationName = poi
                }
                self.spacetimeAnchor = anchor
            } catch {
                // 静默：MVP 阶段定位失败不打扰用户
            }
        }
    }

    // MARK: - 媒体

    /// PhotosPicker 选中变化时调用
    func handlePickerChange() async {
        guard !pickerItems.isEmpty else { return }
        let items = pickerItems
        // 立即清空 picker 绑定，避免用户连续选择时重复触发
        pickerItems.removeAll()

        let includeCloudData = CloudSyncService.shared.isEnabled
            && CloudSyncService.shared.includeMedia
        let total = items.count

        for (index, item) in items.enumerated() {
            // 推断类型用于显示「压缩照片中…」/「压缩视频中…」
            let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) })
            processingMedia = MediaProcessingState(
                kind: isVideo ? .video : .image,
                current: index + 1,
                total: total
            )
            do {
                let attachment = try await AttachmentStore.persist(item, includeCloudData: includeCloudData)
                attachments.append(attachment)
            } catch {
                errorMessage = "媒体保存失败：\(error.localizedDescription)"
            }
        }
        processingMedia = nil
    }

    func removeAttachment(_ attachment: Attachment) {
        attachments.removeAll { $0.id == attachment.id }
        // 删除磁盘文件（imageData 字段会随 Attachment 模型一起被丢弃）
        AttachmentStore.deleteFile(for: attachment)
    }

    // MARK: - 语音转写

    func toggleVoiceCapture() {
        if isRecording {
            speech.stop()
            // 将识别出的文本拼接到草稿
            let recognized = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            if !recognized.isEmpty {
                draftText = draftText.isEmpty ? recognized : "\(draftText) \(recognized)"
            }
            isRecording = false
        } else {
            Task {
                guard await speech.requestAuthorization() else {
                    errorMessage = "需要语音识别与麦克风权限"
                    return
                }
                do {
                    try speech.start()
                    isRecording = true
                } catch {
                    errorMessage = "录音启动失败：\(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - 保存

    /// 持久化为 Memory，写入 SwiftData
    func save(in context: ModelContext) {
        guard !(draftText.isEmpty && attachments.isEmpty) else { return }

        let memory = Memory(
            text: draftText,
            createdAt: spacetimeAnchor?.timestamp ?? Date(),
            locationName: spacetimeAnchor?.locationName,
            latitude: spacetimeAnchor?.coordinate?.lat,
            longitude: spacetimeAnchor?.coordinate?.lon,
            weatherIcon: spacetimeAnchor?.weatherIcon,
            moodTag: selectedMood,
            tags: []
        )
        memory.people = selectedPeople

        context.insert(memory)
        // 附件必须先 insert 到 context，再设 inverse 关系
        for attachment in attachments {
            context.insert(attachment)
            attachment.memory = memory
        }

        do {
            try context.save()
            // 通知 Widget 数据已变化
            WidgetSnapshotPublisher.publish(modelContainer: context.container)
            reset()
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    private func reset() {
        draftText = ""
        attachments = []
        selectedPeople = []
        selectedMood = nil
        captureSpacetimeAnchor()
    }
}
