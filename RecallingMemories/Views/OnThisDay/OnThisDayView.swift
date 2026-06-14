//
//  OnThisDayView.swift
//  拾忆
//
//  「那年今日」专属页 — 进入即看到所有「同月同日」的历史记忆
//

import SwiftUI
import SwiftData

struct OnThisDayView: View {
    @Query(sort: \Memory.createdAt, order: .reverse) private var allMemories: [Memory]
    @State private var detailMemory: Memory?

    private var todayMatches: [Memory] {
        OnThisDayMatcher.match(allMemories, against: Date())
    }

    var body: some View {
        Group {
            if todayMatches.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.clock",
                    title: "今天还没有那年今日",
                    message: "一年后再来这里，会看到今天留下的痕迹。",
                    secondaryHint: "可在「我的 → 通知与推送」开启每日提醒"
                )
            } else {
                List {
                    ForEach(groupedByYear(todayMatches), id: \.year) { group in
                        Section {
                            ForEach(group.items) { memory in
                                Button {
                                    detailMemory = memory
                                } label: {
                                    OnThisDayRow(memory: memory)
                                }
                                .buttonStyle(.plain)
                                .listRowSeparator(.hidden)
                            }
                        } header: {
                            HStack {
                                Text(yearTitle(group.year))
                                    .font(.title3.bold())
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
        }
        .navigationTitle("那年今日")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $detailMemory) { memory in
            MemoryDetailView(memory: memory)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - 按年分组

    private struct YearGroup {
        let year: Int
        let items: [Memory]
    }

    private func groupedByYear(_ memories: [Memory]) -> [YearGroup] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: memories) {
            cal.component(.year, from: $0.createdAt)
        }
        return groups
            .map { YearGroup(year: $0.key, items: $0.value) }
            .sorted { $0.year > $1.year }
    }

    private func yearTitle(_ year: Int) -> String {
        let nowYear = Calendar.current.component(.year, from: Date())
        let diff = nowYear - year
        if diff <= 0 { return "\(year) 年" }
        return "\(diff) 年前 · \(year)"
    }
}

private struct OnThisDayRow: View {
    let memory: Memory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(memory.createdAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let mood = memory.moodTag {
                    Text(mood).font(.caption)
                }
                Spacer()
            }

            if !memory.text.isEmpty {
                Text(memory.text)
                    .font(.body)
                    .lineLimit(4)
            }

            if let location = memory.locationName {
                Label(location, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack { OnThisDayView() }
        .modelContainer(for: [Memory.self, Person.self], inMemory: true)
}
