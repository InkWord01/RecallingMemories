//
//  ShareComposerView.swift
//  拾忆
//
//  分享构图器 —— 模板切换 + 实时预览 + 调起系统分享
//

import SwiftUI

struct ShareComposerView: View {
    let memory: Memory

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: ShareCardTemplate = .minimal
    @State private var renderedImage: UIImage?
    @State private var isRendering = false
    @State private var showShareSheet = false
    @State private var savedToAlbumToast = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                preview
                templateSelector
                actionBar
            }
            .navigationTitle("分享卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
            .background(Color(.systemGroupedBackground))
            .task(id: selectedTemplate) {
                await rerender()
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = renderedImage {
                    ShareSheet(items: [image]) { _ in
                        showShareSheet = false
                    }
                    .presentationDetents([.medium, .large])
                }
            }
            .overlay(alignment: .top) {
                if savedToAlbumToast {
                    toast("已保存到相册")
                }
            }
        }
    }

    // MARK: - 预览

    private var preview: some View {
        ScrollView {
            VStack {
                if let image = renderedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
                        .padding(20)
                } else {
                    // 占位骨架
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.15))
                        .aspectRatio(3.0 / 4.0, contentMode: .fit)
                        .padding(20)
                        .overlay(
                            ProgressView()
                                .controlSize(.large)
                        )
                }
            }
        }
    }

    // MARK: - 模板切换

    private var templateSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ShareCardTemplate.allCases) { template in
                    Button {
                        guard template != selectedTemplate else { return }
                        selectedTemplate = template
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: iconName(for: template))
                                .font(.title3)
                            Text(template.displayName)
                                .font(.caption)
                        }
                        .frame(width: 76, height: 64)
                        .foregroundStyle(template == selectedTemplate ? .white : .primary)
                        .background(
                            template == selectedTemplate ? AnyShapeStyle(Color.accentColor)
                                                         : AnyShapeStyle(.thinMaterial),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private func iconName(for template: ShareCardTemplate) -> String {
        switch template {
        case .minimal:  return "square"
        case .polaroid: return "photo"
        case .kraft:    return "doc.richtext"
        }
    }

    // MARK: - 操作栏

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                saveToAlbum()
            } label: {
                Label("保存到相册", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(renderedImage == nil)

            Button {
                showShareSheet = true
            } label: {
                Label("分享", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(renderedImage == nil)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - 渲染 / 保存

    @MainActor
    private func rerender() async {
        isRendering = true
        // 异步出让一帧，让 selectedTemplate 改变带动 selector 高亮先行
        await Task.yield()
        renderedImage = ShareCardRenderer.render(memory: memory, template: selectedTemplate)
        isRendering = false
    }

    private func saveToAlbum() {
        guard let image = renderedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        withAnimation { savedToAlbumToast = true }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { savedToAlbumToast = false }
        }
    }

    // MARK: - Toast

    private func toast(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThickMaterial, in: Capsule())
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}
