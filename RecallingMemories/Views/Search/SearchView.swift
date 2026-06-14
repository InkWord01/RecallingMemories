//
//  SearchView.swift
//  拾忆
//
//  全局搜索页 — 关键词 + 人物 / 情绪 / 地点 / 时间范围 多维筛选
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Memory.createdAt, order: .reverse) private var allMemories: [Memory]
    @Query(sort: \Person.name) private var allPeople: [Person]

    @State private var query = MemorySearchQuery()
    @State private var showFilters = false
    @State private var detailMemory: Memory?

    private var results: [Memory] {
        MemorySearch.filter(allMemories, by: query)
    }

    /// 出现过的所有 POI（去重）
    private var allLocations: [String] {
        Array(Set(allMemories.compactMap(\.locationName))).sorted()
    }

    /// 出现过的所有情绪标签（去重）
    private var allMoods: [String] {
        Array(Set(allMemories.compactMap(\.moodTag))).sorted()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                activeFilterStrip
                resultList
            }
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query.keyword, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "搜索文字、地点、人物、标签")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: query.isEmpty
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(
                    query: $query,
                    allPeople: allPeople,
                    allMoods: allMoods,
                    allLocations: allLocations
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(item: $detailMemory) { memory in
                MemoryDetailView(memory: memory)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - 已选筛选条件 chip 条

    @ViewBuilder
    private var activeFilterStrip: some View {
        if hasActiveFilters {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let mood = query.moodTag {
                        filterChip(text: mood) { query.moodTag = nil }
                    }
                    if let location = query.locationName {
                        filterChip(text: location, icon: "location.fill") {
                            query.locationName = nil
                        }
                    }
                    ForEach(selectedPeople) { person in
                        filterChip(text: person.name, icon: "person.fill") {
                            query.personIDs.remove(person.id)
                        }
                    }
                    if query.requireAttachments {
                        filterChip(text: "含附件", icon: "paperclip") {
                            query.requireAttachments = false
                        }
                    }
                    if let range = query.dateRange {
                        filterChip(text: dateRangeLabel(range), icon: "calendar") {
                            query.dateRange = nil
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(.ultraThinMaterial)
        }
    }

    private var hasActiveFilters: Bool {
        query.moodTag != nil || query.locationName != nil
            || !query.personIDs.isEmpty || query.requireAttachments
            || query.dateRange != nil
    }

    private var selectedPeople: [Person] {
        allPeople.filter { query.personIDs.contains($0.id) }
    }

    private func filterChip(text: String, icon: String? = nil, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.caption2) }
            Text(text).font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark").font(.caption2)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.tint.opacity(0.15), in: Capsule())
    }

    private func dateRangeLabel(_ range: ClosedRange<Date>) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M/d"
        return "\(f.string(from: range.lowerBound)) – \(f.string(from: range.upperBound))"
    }

    // MARK: - 结果列表

    @ViewBuilder
    private var resultList: some View {
        if query.isEmpty {
            // 空查询：展示热门人物 / 热门地点作为快捷入口
            quickEntries
        } else if results.isEmpty {
            ContentUnavailableView.search
        } else {
            List {
                Section {
                    ForEach(results) { memory in
                        Button {
                            detailMemory = memory
                        } label: {
                            SearchResultRow(memory: memory, keyword: query.keyword)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("\(results.count) 条结果")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
        }
    }

    private var quickEntries: some View {
        List {
            if !allPeople.isEmpty {
                Section("人物") {
                    ForEach(topPeople(8)) { person in
                        Button {
                            query.personIDs = [person.id]
                        } label: {
                            HStack {
                                AvatarView(name: person.name, imagePath: person.avatarPath)
                                    .frame(width: 32, height: 32)
                                Text(person.name)
                                Spacer()
                                Text("\(memoryCount(forPerson: person)) 条")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if !allLocations.isEmpty {
                Section("地点") {
                    ForEach(topLocations(8), id: \.self) { location in
                        Button {
                            query.locationName = location
                        } label: {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundStyle(.orange)
                                Text(location)
                                Spacer()
                                Text("\(memoryCount(forLocation: location)) 条")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if !allMoods.isEmpty {
                Section("情绪") {
                    HStack(spacing: 8) {
                        ForEach(allMoods, id: \.self) { mood in
                            Button {
                                query.moodTag = mood
                            } label: {
                                Text(mood)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.white.opacity(0.08), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - 排行计算

    private func topPeople(_ limit: Int) -> [Person] {
        let counts = Dictionary(
            grouping: allMemories.flatMap(\.people),
            by: \.id
        ).mapValues(\.count)
        return allPeople
            .sorted { (counts[$0.id] ?? 0) > (counts[$1.id] ?? 0) }
            .prefix(limit)
            .map { $0 }
    }

    private func topLocations(_ limit: Int) -> [String] {
        let counts = Dictionary(grouping: allMemories.compactMap(\.locationName), by: { $0 })
            .mapValues(\.count)
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map(\.key)
    }

    private func memoryCount(forPerson person: Person) -> Int {
        allMemories.filter { $0.people.contains(where: { $0.id == person.id }) }.count
    }

    private func memoryCount(forLocation location: String) -> Int {
        allMemories.filter { $0.locationName == location }.count
    }
}

// MARK: - 结果行（带关键词高亮）

private struct SearchResultRow: View {
    let memory: Memory
    let keyword: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            highlightedText(memory.text)
                .font(.body)
                .lineLimit(3)

            HStack(spacing: 8) {
                Text(memory.createdAt, format: .dateTime.year().month().day().hour().minute())
                if let location = memory.locationName {
                    Text("·")
                    Label(location, systemImage: "location.fill")
                }
                if !memory.people.isEmpty {
                    Text("·")
                    Label(memory.people.map(\.name).joined(separator: "、"),
                          systemImage: "person.2.fill")
                }
                if let mood = memory.moodTag {
                    Text(mood)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .padding(.vertical, 6)
    }

    /// 用 AttributedString 给关键词加亮
    @ViewBuilder
    private func highlightedText(_ text: String) -> some View {
        if keyword.isEmpty {
            Text(text)
        } else {
            Text(highlight(text, keyword: keyword))
        }
    }

    private func highlight(_ text: String, keyword: String) -> AttributedString {
        var attributed = AttributedString(text)
        let tokens = keyword.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        for token in tokens where !token.isEmpty {
            var searchRange = attributed.startIndex..<attributed.endIndex
            while let range = attributed.range(of: token, options: .caseInsensitive, locale: nil, in: searchRange) {
                attributed[range].backgroundColor = .yellow.opacity(0.4)
                attributed[range].foregroundColor = .primary
                searchRange = range.upperBound..<attributed.endIndex
            }
        }
        return attributed
    }
}

// MARK: - 筛选面板

private struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var query: MemorySearchQuery
    let allPeople: [Person]
    let allMoods: [String]
    let allLocations: [String]

    @State private var dateFrom: Date = Date().addingTimeInterval(-30 * 86400)
    @State private var dateTo: Date = Date()
    @State private var enableDateRange: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("人物") {
                    if allPeople.isEmpty {
                        Text("还没有添加过人物").foregroundStyle(.secondary)
                    } else {
                        ForEach(allPeople) { person in
                            Button {
                                if query.personIDs.contains(person.id) {
                                    query.personIDs.remove(person.id)
                                } else {
                                    query.personIDs.insert(person.id)
                                }
                            } label: {
                                HStack {
                                    Text(person.name)
                                    Spacer()
                                    if query.personIDs.contains(person.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("情绪") {
                    if allMoods.isEmpty {
                        Text("没有可选的情绪").foregroundStyle(.secondary)
                    } else {
                        Picker("情绪标签", selection: Binding(
                            get: { query.moodTag ?? "" },
                            set: { query.moodTag = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("不限").tag("")
                            ForEach(allMoods, id: \.self) { mood in
                                Text(mood).tag(mood)
                            }
                        }
                    }
                }

                Section("地点") {
                    if allLocations.isEmpty {
                        Text("没有可选的地点").foregroundStyle(.secondary)
                    } else {
                        Picker("POI", selection: Binding(
                            get: { query.locationName ?? "" },
                            set: { query.locationName = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("不限").tag("")
                            ForEach(allLocations, id: \.self) { location in
                                Text(location).tag(location)
                            }
                        }
                    }
                }

                Section("其它") {
                    Toggle("仅含附件", isOn: $query.requireAttachments)
                }

                Section("时间范围") {
                    Toggle("启用时间筛选", isOn: $enableDateRange)
                    if enableDateRange {
                        DatePicker("起", selection: $dateFrom, displayedComponents: .date)
                        DatePicker("止", selection: $dateTo, displayedComponents: .date)
                    }
                }
                .onChange(of: enableDateRange) { _, on in
                    query.dateRange = on ? makeRange() : nil
                }
                .onChange(of: dateFrom) { _, _ in
                    if enableDateRange { query.dateRange = makeRange() }
                }
                .onChange(of: dateTo) { _, _ in
                    if enableDateRange { query.dateRange = makeRange() }
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("重置") {
                        query = MemorySearchQuery(keyword: query.keyword)
                        enableDateRange = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .bold()
                }
            }
            .onAppear {
                if let range = query.dateRange {
                    enableDateRange = true
                    dateFrom = range.lowerBound
                    dateTo = range.upperBound
                }
            }
        }
    }

    private func makeRange() -> ClosedRange<Date> {
        let lower = min(dateFrom, dateTo)
        let upper = max(dateFrom, dateTo)
        // 截到当日 00:00 ~ 次日 00:00 - 1
        let cal = Calendar.current
        let start = cal.startOfDay(for: lower)
        let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: upper))?
            .addingTimeInterval(-1) ?? upper
        return start...end
    }
}

#Preview {
    SearchView()
        .modelContainer(for: Memory.self, inMemory: true)
}
