//
//  PeopleManagementView.swift
//  拾忆
//
//  「我的」→ 人物管理 — 列出所有人物、编辑、合并重复、删除孤儿
//

import SwiftUI
import SwiftData

struct PeopleManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.name) private var people: [Person]
    @Query private var allMemories: [Memory]

    @State private var editingPerson: Person?
    @State private var mergeContext: MergeContext?
    @State private var showOrphansSheet = false

    /// 没有任何 Memory 关联的人物
    private var orphans: [Person] {
        people.filter { person in
            !allMemories.contains(where: { $0.people.contains(where: { $0.id == person.id }) })
        }
    }

    /// 按 displayName 分组，人数 ≥ 2 的视为重名候选合并
    private var duplicates: [String: [Person]] {
        Dictionary(grouping: people, by: \.name).filter { $0.value.count > 1 }
    }

    var body: some View {
        List {
            // 重名提示
            if !duplicates.isEmpty {
                Section {
                    ForEach(Array(duplicates.keys).sorted(), id: \.self) { name in
                        if let group = duplicates[name] {
                            Button {
                                mergeContext = MergeContext(name: name, candidates: group)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.merge")
                                        .foregroundStyle(.orange)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("「\(name)」存在 \(group.count) 个条目")
                                            .font(.subheadline)
                                        Text("点击合并为一条")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("可合并")
                }
            }

            // 孤儿提示
            if !orphans.isEmpty {
                Section {
                    Button {
                        showOrphansSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "person.fill.questionmark")
                                .foregroundStyle(.secondary)
                            Text("有 \(orphans.count) 个人物没有任何记忆关联")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // 全部人物
            Section("全部 (\(people.count))") {
                if people.isEmpty {
                    Text("还没有添加过人物")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(people) { person in
                        Button {
                            editingPerson = person
                        } label: {
                            PersonRow(person: person, count: memoryCount(for: person))
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(person)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("人物管理")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingPerson) { person in
            PersonEditorView(person: person)
                .presentationDetents([.medium])
        }
        .sheet(item: $mergeContext) { ctx in
            MergeView(context: ctx)
        }
        .sheet(isPresented: $showOrphansSheet) {
            OrphansCleanupView(orphans: orphans)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - 数据操作

    private func memoryCount(for person: Person) -> Int {
        allMemories.filter { $0.people.contains(where: { $0.id == person.id }) }.count
    }

    private func delete(_ person: Person) {
        // 先把所有引用解除（防止 SwiftData nullify 后 UI 出现幻影引用）
        for memory in allMemories where memory.people.contains(where: { $0.id == person.id }) {
            memory.people.removeAll { $0.id == person.id }
        }
        modelContext.delete(person)
        try? modelContext.save()
    }
}

// MARK: - 行

private struct PersonRow: View {
    let person: Person
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: person.name, imagePath: person.avatarPath)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.body)
                HStack(spacing: 6) {
                    Text("\(count) 条记忆")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if person.contactIdentifier != nil {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Label("通讯录", systemImage: "person.crop.circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 编辑

private struct PersonEditorView: View {
    @Bindable var person: Person
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draftName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("姓名") {
                    TextField("姓名或称呼", text: $draftName)
                        .textInputAutocapitalization(.never)
                }

                if person.contactIdentifier != nil {
                    Section {
                        HStack {
                            Image(systemName: "link")
                                .foregroundStyle(.secondary)
                            Text("已关联系统通讯录")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("解除") {
                                person.contactIdentifier = nil
                            }
                            .font(.caption)
                        }
                    } footer: {
                        Text("解除后，该人物会变成自定义条目，不再从通讯录同步信息。")
                    }
                }
            }
            .navigationTitle("编辑人物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        save()
                        dismiss()
                    }
                    .bold()
                    .disabled(draftName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                draftName = person.name
            }
        }
    }

    private func save() {
        let trimmed = draftName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        person.name = trimmed
        try? modelContext.save()
    }
}

// MARK: - 合并

private struct MergeContext: Identifiable {
    let id = UUID()
    let name: String
    let candidates: [Person]
}

private struct MergeView: View {
    let context: MergeContext

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allMemories: [Memory]

    @State private var keeperID: UUID?

    private var keeper: Person? {
        context.candidates.first { $0.id == keeperID }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("「\(context.name)」有 \(context.candidates.count) 个条目，选择一个保留，其余将合并到它，所有关联的记忆都会迁移过来。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("选择要保留的条目") {
                    ForEach(context.candidates) { person in
                        Button {
                            keeperID = person.id
                        } label: {
                            HStack {
                                Image(systemName: keeperID == person.id
                                      ? "largecircle.fill.circle"
                                      : "circle")
                                    .foregroundStyle(keeperID == person.id ? .tint : .secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(person.name)
                                    Text("\(memoryCount(for: person)) 条记忆")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if person.contactIdentifier != nil {
                                        Label("已关联通讯录", systemImage: "person.crop.circle")
                                            .font(.caption2)
                                            .foregroundStyle(.tint)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("合并人物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("合并") {
                        performMerge()
                        dismiss()
                    }
                    .bold()
                    .disabled(keeperID == nil)
                }
            }
            .onAppear {
                // 默认选中关联记忆最多的（含通讯录优先）
                let sorted = context.candidates.sorted { lhs, rhs in
                    let lc = memoryCount(for: lhs)
                    let rc = memoryCount(for: rhs)
                    if lc != rc { return lc > rc }
                    return (lhs.contactIdentifier != nil) && (rhs.contactIdentifier == nil)
                }
                keeperID = sorted.first?.id
            }
        }
    }

    private func memoryCount(for person: Person) -> Int {
        allMemories.filter { $0.people.contains(where: { $0.id == person.id }) }.count
    }

    private func performMerge() {
        guard let keeper else { return }
        let losers = context.candidates.filter { $0.id != keeper.id }
        let loserIDs = Set(losers.map(\.id))

        // 把所有关联到 loser 的 memory，把引用替换为 keeper（去重）
        for memory in allMemories where memory.people.contains(where: { loserIDs.contains($0.id) }) {
            // 移除所有 loser
            memory.people.removeAll { loserIDs.contains($0.id) }
            // 如果 keeper 还没在列表里就补上
            if !memory.people.contains(where: { $0.id == keeper.id }) {
                memory.people.append(keeper)
            }
        }

        // 删除 losers
        for loser in losers {
            modelContext.delete(loser)
        }

        try? modelContext.save()
    }
}

// MARK: - 孤儿清理

private struct OrphansCleanupView: View {
    let orphans: [Person]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("以下人物还没有任何记忆关联，多见于添加后未使用，或合并后留下的痕迹。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("选择要删除的") {
                    ForEach(orphans) { person in
                        Button {
                            toggle(person)
                        } label: {
                            HStack {
                                Image(systemName: selection.contains(person.id)
                                      ? "checkmark.circle.fill"
                                      : "circle")
                                    .foregroundStyle(selection.contains(person.id) ? .red : .secondary)
                                AvatarView(name: person.name, imagePath: person.avatarPath)
                                    .frame(width: 32, height: 32)
                                Text(person.name)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("清理孤儿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(selection.count == orphans.count ? "全不选" : "全选") {
                        if selection.count == orphans.count {
                            selection.removeAll()
                        } else {
                            selection = Set(orphans.map(\.id))
                        }
                    }
                    .font(.caption)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        deleteSelected()
                        dismiss()
                    } label: {
                        Text(selection.isEmpty ? "删除" : "删除 \(selection.count) 个")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(selection.isEmpty)
                }
            }
        }
    }

    private func toggle(_ person: Person) {
        if selection.contains(person.id) {
            selection.remove(person.id)
        } else {
            selection.insert(person.id)
        }
    }

    private func deleteSelected() {
        for person in orphans where selection.contains(person.id) {
            modelContext.delete(person)
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack { PeopleManagementView() }
        .modelContainer(for: [Memory.self, Person.self], inMemory: true)
}
