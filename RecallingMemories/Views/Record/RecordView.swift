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
    @StateObject private var viewModel = RecordViewModel()

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
                    Text(viewModel.isRecording ? "聆听中…" : "记录此刻的想法…")
                        .foregroundStyle(.secondary)
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
                            Text(person.name)
                                .font(.caption)
                            Button {
                                viewModel.selectedPeople.removeAll { $0.id == person.id }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.08), in: Capsule())
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 40)
        }
    }

    // MARK: - 附件缩略图条

    @ViewBuilder
    private var attachmentStrip: some View {
        if !viewModel.attachments.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.attachments) { attachment in
                        ZStack(alignment: .topTrailing) {
                            AsyncThumbnailView(attachment: attachment)
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Button {
                                viewModel.removeAttachment(attachment)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white, .black.opacity(0.6))
                                    .background(Circle().fill(.ultraThinMaterial))
                            }
                            .offset(x: 4, y: -4)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 88)
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
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 36)
    }

    // MARK: - 工具条

    private var anchorToolbar: some View {
        HStack(spacing: 16) {
            PhotosPicker(selection: $viewModel.pickerItems, maxSelectionCount: 9, matching: .any(of: [.images, .videos])) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title3)
                    .frame(width: 36, height: 36)
            }

            Button {
                viewModel.toggleVoiceCapture()
            } label: {
                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.fill")
                    .font(.title3)
                    .foregroundStyle(viewModel.isRecording ? .red : .primary)
                    .frame(width: 36, height: 36)
            }

            Button {
                showPeoplePicker = true
            } label: {
                Image(systemName: viewModel.selectedPeople.isEmpty ? "person.2" : "person.2.fill")
                    .font(.title3)
                    .foregroundStyle(viewModel.selectedPeople.isEmpty ? .primary : .tint)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Button {
                viewModel.save(in: modelContext)
            } label: {
                Text("保存")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .disabled(viewModel.draftText.isEmpty && viewModel.attachments.isEmpty)
        }
        .padding()
        .background(.ultraThinMaterial)
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
            let url = AttachmentStore.url(for: attachment)
            if let data = try? Data(contentsOf: url),
               let img = UIImage(data: data) {
                self.image = img
            }
        }
    }
}

#Preview {
    RecordView()
        .modelContainer(for: [Memory.self, Person.self], inMemory: true)
}
