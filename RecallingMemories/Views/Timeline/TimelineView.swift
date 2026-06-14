//
//  TimelineView.swift
//  拾忆
//
//  时光轴 — 按日期分组（今天/昨天/本周/更早），缩略图网格、人物、地点一览
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memory.createdAt, order: .reverse) private var memories: [Memory]

    @State private var selectedMemory: Memory?
    @State private var showSearch = false
    @State private var sharingMemory: Memory?

    var body: some View {
        NavigationStack {
            Group {
                if memories.isEmpty {
                    ContentUnavailableView(
                        "还没有记忆",
                        systemImage: "sparkles",
                        description: Text("记录此刻，让一瞬间留下痕迹。")
                    )
                } else {
                    timelineList
                }
            }
            .navigationTitle("时光")
            .toolbar {
                if !memories.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
            }
            .sheet(item: $selectedMemory) { memory in
                MemoryDetailView(memory: memory)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
            }
            .sheet(item: $sharingMemory) { memory in
                ShareComposerView(memory: memory)
            }
        }
    }

    // MARK: - 列表

    private var timelineList: some View {
        List {
            ForEach(groupedMemories, id: \.title) { group in
                Section {
                    ForEach(group.items) { memory in
                        Button {
                            selectedMemory = memory
                        } label: {
                            MemoryRow(memory: memory)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(memory)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            Button {
                                sharingMemory = memory
                            } label: {
                                Label("分享", systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                    }
                } header: {
                    HStack {
                        Text(group.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(group.items.count) 条")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - 分组

    private var groupedMemories: [MemoryGroup] {
        TimelineGrouping.group(memories)
    }

    private func delete(_ memory: Memory) {
        // 删除磁盘上的附件文件
        for attachment in memory.attachments {
            try? FileManager.default.removeItem(at: AttachmentStore.url(for: attachment))
        }
        modelContext.delete(memory)
        try? modelContext.save()
        // 通知 Widget 刷新
        WidgetSnapshotPublisher.publish(modelContainer: modelContext.container)
    }
}

// MARK: - Memory Row

private struct MemoryRow: View {
    let memory: Memory

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 时间 + 情绪
            HStack(spacing: 6) {
                Text(memory.createdAt, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let mood = memory.moodTag {
                    Text(mood)
                        .font(.caption)
                }
                Spacer()
            }

            // 文本
            if !memory.text.isEmpty {
                Text(memory.text)
                    .font(.body)
                    .lineLimit(6)
            }

            // 缩略图网格
            if !memory.attachments.isEmpty {
                ThumbnailGrid(attachments: memory.attachments)
            }

            // 元信息：地点 / 人物
            metaFooter
        }
        .padding(12)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var metaFooter: some View {
        let hasLocation = memory.locationName != nil
        let hasPeople = !memory.people.isEmpty

        if hasLocation || hasPeople {
            HStack(spacing: 12) {
                if let location = memory.locationName {
                    Label(location, systemImage: "location.fill")
                }
                if hasPeople {
                    Label(
                        memory.people.prefix(3).map(\.name).joined(separator: "、")
                            + (memory.people.count > 3 ? "等\(memory.people.count)人" : ""),
                        systemImage: "person.2.fill"
                    )
                }
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
    }
}

// MARK: - 缩略图网格（最多 9 宫格）

private struct ThumbnailGrid: View {
    let attachments: [Attachment]

    private var columns: [GridItem] {
        let n = min(attachments.count, 3)
        return Array(repeating: GridItem(.flexible(), spacing: 4), count: max(n, 1))
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(attachments.prefix(9)) { attachment in
                AsyncThumbnailView(attachment: attachment)
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(alignment: .bottomTrailing) {
                        if attachment.kind == .video {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white, .black.opacity(0.5))
                                .padding(4)
                        }
                    }
            }
        }
    }
}

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
    TimelineView()
        .modelContainer(for: [Memory.self, Person.self], inMemory: true)
}
