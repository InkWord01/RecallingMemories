//
//  RecordView.swift
//  拾忆
//
//  极速记录页 — 启动即写、富媒体挂载、时空锚点、语音转写、情绪标签
//

import SwiftUI
import PhotosUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel = RecordViewModel()
    @ObservedObject private var router = AppRouter.shared

    @FocusState private var isInputFocused: Bool
    @State private var showPeoplePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputArea
                peopleStrip
                attachmentStrip
                moodPicker
                anchorToolbar
            }
            .navigationTitle("此刻")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isInputFocused = true
                viewModel.captureSpacetimeAnchor()
            }
            .onChange(of: router.requestQuickRecordFocus) { _, requested in
                // 来自 Widget「快速记录」深链：重置状态 + 聚焦输入框
                guard requested else { return }
                isInputFocused = true
                viewModel.captureSpacetimeAnchor()
                router.requestQuickRecordFocus = false
            }
            .onChange(of: viewModel.pickerItems) { _, _ in
                Task { await viewModel.handlePickerChange() }
            }
            .alert(
                "提示",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                presenting: viewModel.errorMessage
            ) { _ in
                Button("好") { viewModel.errorMessage = nil }
            } message: { message in
                Text(message)
            }
            .sheet(isPresented: $showPeoplePicker) {
                PeoplePickerView(selected: $viewModel.selectedPeople)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - 输入区

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.draftText)
                    .focused($isInputFocused)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)

                if viewModel.draftText.isEmpty {
                    HStack(spacing: 6) {
                        if viewModel.isRecording && !reduceMotion {
                            // 红色呼吸圆点 — 让「聆听中」有生命感（reduce motion 下隐藏）
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                                .phaseAnimator([1.0, 0.4]) { content, phase in
                                    content.opacity(phase)
                                } animation: { _ in
                                    .easeInOut(duration: 0.7)
                                }
                                .accessibilityHidden(true)
                        }
                        Text(viewModel.isRecording ? "聆听中…" : "记录此刻的想法…")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 18)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
                }
            }

            if let anchor = viewModel.spacetimeAnchor {
                HStack(spacing: 12) {
                    Label(anchor.timeDescription, systemImage: "clock")
                    if let location = anchor.locationName {
                        Label(location, systemImage: "location.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .frame(maxHeight: .infinity)
    }

    // MARK: - 已选人物条

    @ViewBuilder
    private var peopleStrip: some View {
        if !viewModel.selectedPeople.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.selectedPeople) { person in
                        HStack(spacing: 6) {
                            AvatarView(name: person.name, imagePath: person.avatarPath)
                                .frame(width: 20, height: 20)
                                .accessibilityHidden(true)
                            Text(person.name)
                                .font(.caption)
                            Button {
                                viewModel.selectedPeople.removeAll { $0.id == person.id }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityLabel("移除 \(person.name)")
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.08), in: Capsule())
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 40)
            .accessibilityLabel("已选人物")
        }
    }

    // MARK: - 附件缩略图条

    @ViewBuilder
    private var attachmentStrip: some View {
        if !viewModel.attachments.isEmpty || viewModel.processingMedia != nil {
            VStack(spacing: 6) {
                // 顶部进度胶囊（仅处理中显示）
                if let processing = viewModel.processingMedia {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text(processing.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityLabel(processing.label)
                }

                if !viewModel.attachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.attachments) { attachment in
                                ZStack(alignment: .topTrailing) {
                                    AsyncThumbnailView(attachment: attachment)
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .accessibilityLabel(accessibilityLabel(for: attachment))

                                    Button {
                                        viewModel.removeAttachment(attachment)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white, .black.opacity(0.6))
                                            .background(Circle().fill(.ultraThinMaterial))
                                    }
                                    .offset(x: 4, y: -4)
                                    .accessibilityLabel("移除附件")
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 88)
                    .accessibilityLabel("已添加的媒体附件")
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.processingMedia)
        }
    }

    private func accessibilityLabel(for attachment: Attachment) -> String {
        switch attachment.kind {
        case .photo:     return "照片"
        case .livePhoto: return "实况照片"
        case .video:     return "视频"
        case .audio:     return "音频"
        }
    }

    // MARK: - 情绪标签

    private var moodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.moodOptions, id: \.self) { mood in
                    let selected = viewModel.selectedMood == mood
                    Button {
                        viewModel.selectedMood = selected ? nil : mood
                    } label: {
                        Text(mood)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selected ? .white.opacity(0.2) : .white.opacity(0.06),
                                        in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Mood.accessibilityLabel(for: mood))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 36)
        .accessibilityLabel("情绪标签")
    }

    // MARK: - 工具条

    private var anchorToolbar: some View {
        HStack(spacing: 16) {
            PhotosPicker(selection: $viewModel.pickerItems, maxSelectionCount: 9, matching: .any(of: [.images, .videos])) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title3)
                    .foregroundStyle(viewModel.processingMedia != nil ? Color.secondary : Color.primary)
                    .frame(width: 36, height: 36)
            }
            .disabled(viewModel.processingMedia != nil)
            .accessibilityLabel("添加照片或视频")

            Button {
                viewModel.toggleVoiceCapture()
            } label: {
                ZStack {
                    if viewModel.isRecording && !reduceMotion {
                        // 用 PhaseAnimator 做向外扩散的脉冲（iOS 17+，reduce motion 下隐藏）
                        Circle()
                            .stroke(.red.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 36, height: 36)
                            .phaseAnimator([0, 1]) { content, phase in
                                content
                                    .scaleEffect(1.0 + 0.6 * phase)
                                    .opacity(1.0 - phase)
                            } animation: { _ in
                                .easeOut(duration: 1.2)
                            }
                            .accessibilityHidden(true)
                    }
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.title3)
                        .foregroundStyle(viewModel.isRecording ? .red : .primary)
                        .frame(width: 36, height: 36)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .accessibilityLabel(viewModel.isRecording ? "停止录音" : "开始语音转文字")
            .accessibilityHint(viewModel.isRecording ? "点击停止录音并把识别结果加入草稿" : "录音时会持续把语音转成文字")

            Button {
                showPeoplePicker = true
            } label: {
                Image(systemName: viewModel.selectedPeople.isEmpty ? "person.2" : "person.2.fill")
                    .font(.title3)
                    .foregroundStyle(viewModel.selectedPeople.isEmpty ? .primary : .tint)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("和谁在一起")
            .accessibilityValue(viewModel.selectedPeople.isEmpty
                                ? "未选择"
                                : "已选 \(viewModel.selectedPeople.count) 人")

            Spacer()

            // 保存按钮 — 高度对齐到 36，启用态平滑过渡
            Button {
                viewModel.save(in: modelContext)
            } label: {
                Text("保存")
                    .font(.subheadline.bold())
                    .frame(height: 36)
                    .padding(.horizontal, 18)
                    .background(canSave ? AnyShapeStyle(.tint) : AnyShapeStyle(.ultraThinMaterial),
                                in: Capsule())
                    .foregroundStyle(canSave ? Color.white : Color.secondary)
                    .animation(.easeInOut(duration: 0.2), value: canSave)
            }
            .disabled(!canSave)
            .accessibilityHint(canSave ? "保存当前记忆到时光轴" : "需要先输入文字或添加附件")
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var canSave: Bool {
        !viewModel.draftText.isEmpty || !viewModel.attachments.isEmpty
    }
}

/// 异步加载本地附件缩略图
private struct AsyncThumbnailView: View {
    let attachment: Attachment
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .overlay(ProgressView().controlSize(.small))
            }
        }
        .task(id: attachment.id) {
            if let data = AttachmentStore.loadData(for: attachment),
               let img = UIImage(data: data) {
                self.image = img
            }
        }
    }
}

#Preview {
    RecordView()
        .modelContainer(for: [Memory.self, Person.self, Attachment.self], inMemory: true)
}
