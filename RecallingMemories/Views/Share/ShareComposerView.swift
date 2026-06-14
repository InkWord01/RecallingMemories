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
    @State private var statusToast: String?
    @State private var showProAlert = false

    private var isWeChatAvailable: Bool {
        WeChatService.shared.isWeChatInstalled
    }

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
                } else if let status = statusToast {
                    toast(status)
                }
            }
            .alert("敬请期待", isPresented: $showProAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("Pro 模板正在打磨中，将在后续版本推出。")
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
                        if template.isPro {
                            showProAlert = true
                        } else if template != selectedTemplate {
                            selectedTemplate = template
                        }
                    } label: {
                        templateChip(template: template)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private func templateChip(template: ShareCardTemplate) -> some View {
        let isSelected = template == selectedTemplate
        return ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Image(systemName: template.icon)
                    .font(.title3)
                Text(template.displayName)
                    .font(.caption)
            }
            .frame(width: 76, height: 64)
            .foregroundStyle(
                isSelected ? .white :
                (template.isPro ? Color.secondary : Color.primary)
            )
            .background(
                isSelected ? AnyShapeStyle(Color.accentColor)
                            : AnyShapeStyle(.thinMaterial),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .opacity(template.isPro ? 0.7 : 1.0)

            if template.isPro {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Color.orange, in: Circle())
                    .offset(x: 6, y: -6)
            }
        }
    }

    // MARK: - 操作栏

    private var actionBar: some View {
        VStack(spacing: 8) {
            // 微信直发（仅安装时显示）
            if isWeChatAvailable {
                HStack(spacing: 12) {
                    weChatButton(label: "好友", icon: "message.fill", scene: .session)
                    weChatButton(label: "朋友圈", icon: "person.3.fill", scene: .timeline)
                    weChatButton(label: "收藏", icon: "star.fill", scene: .favorite)
                }
            }

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
                    Label("更多", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(renderedImage == nil)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func weChatButton(label: String, icon: String, scene: WeChatService.SharingScene) -> some View {
        Button {
            Task { await sendToWeChat(scene: scene) }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(Color.green)
        }
        .buttonStyle(.plain)
        .disabled(renderedImage == nil)
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

    /// 调起微信 SDK 直发
    private func sendToWeChat(scene: WeChatService.SharingScene) async {
        guard let image = renderedImage else { return }
        let ok = await WeChatService.shared.shareImage(image, scene: scene)
        await showStatus(ok ? "已发送" : "发送已取消")
    }

    @MainActor
    private func showStatus(_ text: String) async {
        withAnimation { statusToast = text }
        try? await Task.sleep(for: .seconds(1.5))
        withAnimation { statusToast = nil }
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
