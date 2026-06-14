//
//  RecordView.swift
//  拾忆
//
//  极速记录页 — 启动即写、富媒体挂载、时空锚点
//

import SwiftUI
import PhotosUI

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = RecordViewModel()

    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 输入区（占首屏 1/3）
                inputArea
                    .frame(maxHeight: .infinity)

                // 媒体 / 时空锚点 工具条
                anchorToolbar
            }
            .navigationTitle("此刻")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 启动即写：自动聚焦输入框
                isInputFocused = true
                viewModel.captureSpacetimeAnchor()
            }
        }
    }

    // MARK: - 输入区

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $viewModel.draftText)
                .focused($isInputFocused)
                .scrollContentBackground(.hidden)
                .padding(.horizontal)
                .overlay(alignment: .topLeading) {
                    if viewModel.draftText.isEmpty {
                        Text("记录此刻的想法…")
                            .foregroundStyle(.secondary)
                            .padding(.leading, 20)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }

            // 时空锚点显示
            if let anchor = viewModel.spacetimeAnchor {
                HStack(spacing: 8) {
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
    }

    // MARK: - 工具条

    private var anchorToolbar: some View {
        HStack(spacing: 24) {
            toolButton(icon: "camera.fill", action: viewModel.openCamera)
            toolButton(icon: "photo.on.rectangle", action: viewModel.openPhotoLibrary)
            toolButton(icon: "mic.fill", action: viewModel.startVoiceCapture)
            toolButton(icon: "person.2.fill", action: viewModel.tagPeople)

            Spacer()

            Button(action: viewModel.save) {
                Text("保存")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .disabled(viewModel.draftText.isEmpty && viewModel.attachments.isEmpty)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func toolButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
        }
    }
}

#Preview {
    RecordView()
}
