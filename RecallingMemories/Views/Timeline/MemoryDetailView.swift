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
            .navigationTitle(memory.createdAt.formatted(date: .abbreviated, time: .shortened))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareComposer = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareComposer) {
                ShareComposerView(memory: memory)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let mood = memory.moodTag {
                Text(mood).font(.title2)
            }
            VStack(alignment: .leading, spacing: 4) {
                if let location = memory.locationName {
                    Label(location, systemImage: "location.fill")
                        .font(.subheadline)
                }
                Text(memory.createdAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                        .frame(height: 240)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: memory.attachments.count > 1 ? .always : .never))
        .frame(height: 320)
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
