//
//  TimelineView.swift
//  拾忆
//
//  时光轴 / 瀑布流
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \Memory.createdAt, order: .reverse) private var memories: [Memory]

    var body: some View {
        NavigationStack {
            if memories.isEmpty {
                ContentUnavailableView(
                    "还没有记忆",
                    systemImage: "sparkles",
                    description: Text("记录此刻，让一瞬间留下痕迹。")
                )
            } else {
                List(memories) { memory in
                    MemoryRow(memory: memory)
                }
                .listStyle(.plain)
                .navigationTitle("时光")
            }
        }
    }
}

private struct MemoryRow: View {
    let memory: Memory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(memory.text)
                .font(.body)

            HStack(spacing: 8) {
                Text(memory.createdAt, style: .date)
                if let location = memory.locationName {
                    Text("·")
                    Text(location)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: Memory.self, inMemory: true)
}
