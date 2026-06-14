//
//  MemoryDetailView.swift
//  拾忆
//
//  时间轴点击单条记忆 → 弹出详情（半屏 / 全屏 sheet）
//

import SwiftUI

struct MemoryDetailView: View {
    let memory: Memory

    @State private var showShareComposer = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 顶部时空信息
                    header

                    // 文本
                    if !memory.text.isEmpty {
                        Text(memory.text)
                            .font(.title3)
                            .lineSpacing(4)
                    }

                    // 媒体
                    if !memory.attachments.isEmpty {
                        mediaGallery
                    }

                    // 人物
                    if !memory.people.isEmpty {
                        peopleSection
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle(navigationTitleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareComposer = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("分享这条记忆")
                }
            }
            .sheet(isPresented: $showShareComposer) {
                ShareComposerView(memory: memory)
            }
        }
    }

    /// 紧凑的标题 — 只显示「6 月 14 日 · 09:32」
    private var navigationTitleText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M 月 d 日 · HH:mm"
        return f.string(from: memory.createdAt)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            if let mood = memory.moodTag {
                Text(mood)
                    .font(.system(size: 36))
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel(Mood.accessibilityLabel(for: mood))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(memory.createdAt, format: .dateTime.year().month().day().weekday(.wide))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let location = memory.locationName {
                    Label(location, systemImage: "location.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                }
            }
            Spacer()
        }
    }

    private var mediaGallery: some View {
        TabView {
            ForEach(memory.attachments) { attachment in
                if let image = loadImage(attachment) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .aspectRatio(4.0 / 3.0, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: memory.attachments.count > 1 ? .always : .never))
        // 自适应：竖图维持原比例（最多 480 高），横图最多 320
        .frame(minHeight: 240, maxHeight: 480)
    }

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("和谁在一起", systemImage: "person.2.fill")
                .font(.subheadline.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(memory.people) { person in
                        VStack(spacing: 6) {
                            AvatarView(name: person.name, imagePath: person.avatarPath)
                                .frame(width: 48, height: 48)
                            Text(person.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .frame(width: 64)
                    }
                }
            }
        }
    }

    private func loadImage(_ attachment: Attachment) -> UIImage? {
        let url = AttachmentStore.url(for: attachment)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
