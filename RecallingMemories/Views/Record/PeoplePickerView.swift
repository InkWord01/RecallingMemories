//
//  PeoplePickerView.swift
//  拾忆
//
//  「和谁在一起」选择面板 — 通讯录 + 已存历史人物 + 自定义新增
//

import SwiftUI
import SwiftData
import Contacts

struct PeoplePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// 已选中的人物（绑定回 RecordViewModel）
    @Binding var selected: [Person]

    @Query(sort: \Person.name) private var savedPeople: [Person]

    @State private var contacts: [ContactItem] = []
    @State private var isLoadingContacts = false
    @State private var contactsAuthorized = false
    @State private var keyword: String = ""
    @State private var showCustomInput = false
    @State private var customName: String = ""

    private var filteredSaved: [Person] {
        guard !keyword.isEmpty else { return savedPeople }
        return savedPeople.filter { $0.name.localizedCaseInsensitiveContains(keyword) }
    }

    private var filteredContacts: [ContactItem] {
        // 已经存为 Person 的联系人不再重复出现
        let savedIdentifiers = Set(savedPeople.compactMap { $0.contactIdentifier })
        let remaining = contacts.filter { !savedIdentifiers.contains($0.identifier) }
        guard !keyword.isEmpty else { return remaining }
        return remaining.filter { $0.displayName.localizedCaseInsensitiveContains(keyword) }
    }

    var body: some View {
        NavigationStack {
            List {
                // 已选中
                if !selected.isEmpty {
                    Section("已选中 (\(selected.count))") {
                        ForEach(selected) { person in
                            personRow(name: person.name, avatar: person.avatarPath, selected: true) {
                                toggle(person)
                            }
                        }
                    }
                }

                // 自定义新增入口
                Section {
                    Button {
                        showCustomInput = true
                    } label: {
                        Label("自定义添加", systemImage: "plus.circle.fill")
                    }
                }

                // 已存的人物
                if !filteredSaved.isEmpty {
                    Section("常用") {
                        ForEach(filteredSaved) { person in
                            let isSelected = selected.contains(where: { $0.id == person.id })
                            personRow(name: person.name, avatar: person.avatarPath, selected: isSelected) {
                                toggle(person)
                            }
                        }
                    }
                }

                // 通讯录
                Section("通讯录") {
                    if !contactsAuthorized {
                        Button {
                            Task { await loadContacts() }
                        } label: {
                            Label("授权访问通讯录", systemImage: "person.crop.circle.badge.plus")
                        }
                    } else if isLoadingContacts {
                        HStack {
                            ProgressView().controlSize(.small)
                            Text("加载中…").foregroundStyle(.secondary)
                        }
                    } else if filteredContacts.isEmpty {
                        Text(keyword.isEmpty ? "没有更多联系人" : "未找到匹配")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredContacts) { item in
                            contactRow(item: item) {
                                addFromContact(item)
                            }
                        }
                    }
                }
            }
            .searchable(text: $keyword, prompt: "搜索人物")
            .navigationTitle("和谁在一起")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        selected.removeAll()
                        dismiss()
                    }
                }
            }
            .alert("自定义人物", isPresented: $showCustomInput) {
                TextField("姓名或称呼", text: $customName)
                Button("添加", action: addCustom)
                Button("取消", role: .cancel) { customName = "" }
            }
            .task {
                // 自动尝试加载（已授权场景下无感）
                if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                    await loadContacts()
                }
            }
        }
    }

    // MARK: - 行

    private func personRow(name: String, avatar: String?, selected isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AvatarView(name: name, imagePath: avatar)
                    .frame(width: 36, height: 36)
                Text(name)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func contactRow(item: ContactItem, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AvatarView(name: item.displayName, thumbnailData: item.thumbnailData)
                    .frame(width: 36, height: 36)
                Text(item.displayName)
                Spacer()
                Image(systemName: "plus.circle")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 数据操作

    private func toggle(_ person: Person) {
        if let idx = selected.firstIndex(where: { $0.id == person.id }) {
            selected.remove(at: idx)
        } else {
            selected.append(person)
        }
    }

    private func addFromContact(_ item: ContactItem) {
        let person = Person(
            name: item.displayName,
            contactIdentifier: item.identifier,
            avatarPath: nil
        )
        modelContext.insert(person)
        try? modelContext.save()
        selected.append(person)
    }

    private func addCustom() {
        let name = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        defer { customName = "" }
        guard !name.isEmpty else { return }
        let person = Person(name: name)
        modelContext.insert(person)
        try? modelContext.save()
        selected.append(person)
    }

    private func loadContacts() async {
        isLoadingContacts = true
        defer { isLoadingContacts = false }
        do {
            let items = try await ContactsService.shared.fetchAll()
            self.contacts = items
            self.contactsAuthorized = true
        } catch {
            self.contactsAuthorized = false
        }
    }
}

/// 通用头像视图：优先图片，其次首字母占位
struct AvatarView: View {
    let name: String
    var imagePath: String?
    var thumbnailData: Data?

    var body: some View {
        Group {
            if let data = thumbnailData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
            } else if let path = imagePath,
                      let img = UIImage(contentsOfFile: AttachmentStore.rootURL.appendingPathComponent(path).path) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                Circle()
                    .fill(Color(hue: hue, saturation: 0.5, brightness: 0.7))
                    .overlay(
                        Text(initial)
                            .font(.headline)
                            .foregroundStyle(.white)
                    )
            }
        }
        .clipShape(Circle())
    }

    private var initial: String {
        String(name.prefix(1))
    }

    /// 通过名字 hash 派生稳定的颜色
    private var hue: Double {
        let h = abs(name.hashValue % 360)
        return Double(h) / 360.0
    }
}
