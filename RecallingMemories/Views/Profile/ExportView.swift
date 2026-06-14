//
//  ExportView.swift
//  拾忆
//
//  数据导出 — 选择格式 / 时间范围 → 生成文件 → 系统分享
//

import SwiftUI
import SwiftData

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memory.createdAt, order: .reverse) private var allMemories: [Memory]

    @State private var format: ExportFormat = .markdown
    @State private var range: TimeRange = .all
    @State private var customFrom: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customTo: Date = Date()

    @State private var isExporting = false
    @State private var exportedFile: ExportedFile?
    @State private var errorMessage: String?

    private var filteredMemories: [Memory] {
        switch range {
        case .all:
            return allMemories
        case .lastMonth:
            let cutoff = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? .distantPast
            return allMemories.filter { $0.createdAt >= cutoff }
        case .lastYear:
            let cutoff = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? .distantPast
            return allMemories.filter { $0.createdAt >= cutoff }
        case .custom:
            let lower = min(customFrom, customTo)
            let upper = max(customFrom, customTo)
            let cal = Calendar.current
            let start = cal.startOfDay(for: lower)
            let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: upper)) ?? upper
            return allMemories.filter { $0.createdAt >= start && $0.createdAt < end }
        }
    }

    var body: some View {
        Form {
            Section("格式") {
                Picker("导出为", selection: $format) {
                    ForEach(ExportFormat.allCases) { fmt in
                        Label(fmt.displayName, systemImage: fmt.icon).tag(fmt)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } footer: {
                Text(format.description)
            }

            Section("时间范围") {
                Picker("范围", selection: $range) {
                    ForEach(TimeRange.allCases) { r in
                        Text(r.displayName).tag(r)
                    }
                }
                if range == .custom {
                    DatePicker("起", selection: $customFrom, displayedComponents: .date)
                    DatePicker("止", selection: $customTo, displayedComponents: .date)
                }
            }

            Section {
                HStack {
                    Text("将导出")
                    Spacer()
                    Text("\(filteredMemories.count) 条记忆")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    Task { await runExport() }
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView().controlSize(.small)
                            Text("正在导出…")
                        } else {
                            Image(systemName: "square.and.arrow.up")
                            Text("生成并分享")
                                .bold()
                        }
                        Spacer()
                    }
                }
                .disabled(filteredMemories.isEmpty || isExporting)
            } footer: {
                Text("生成的文件将存放在临时目录，关闭分享面板后可能被系统清理；建议直接分享到「文件」/iCloud Drive 长期保存。")
            }
        }
        .navigationTitle("数据导出")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $exportedFile) { file in
            ShareSheet(items: [file.url]) { _ in
                exportedFile = nil
            }
            .presentationDetents([.medium, .large])
        }
        .alert("导出失败", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        ), presenting: errorMessage) { _ in
            Button("好") { errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: - 导出执行

    @MainActor
    private func runExport() async {
        isExporting = true
        defer { isExporting = false }

        let memories = filteredMemories
        let stamp = stampString()

        // 让 SwiftUI 先把 ProgressView 渲染出来（出让一帧），再开始重 IO
        await Task.yield()

        do {
            let url: URL
            switch format {
            case .markdown:
                url = try MarkdownExporter.writeBundle(memories: memories)
            case .markdownSingle:
                let text = MarkdownExporter.render(memories: memories)
                url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("拾忆_\(stamp).md")
                try text.data(using: .utf8)?.write(to: url, options: .atomic)
            case .pdf:
                url = try PDFExporter.write(memories: memories)
            }
            exportedFile = ExportedFile(url: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func stampString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: Date())
    }
}

// MARK: - 选项

enum ExportFormat: String, CaseIterable, Identifiable {
    case markdownSingle
    case markdown
    case pdf

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .markdownSingle: return "Markdown（单文件）"
        case .markdown:       return "Markdown（含附件）"
        case .pdf:            return "PDF 时光书"
        }
    }

    var icon: String {
        switch self {
        case .markdownSingle: return "doc.text"
        case .markdown:       return "doc.zipper"
        case .pdf:            return "doc.richtext"
        }
    }

    var description: String {
        switch self {
        case .markdownSingle:
            return "纯文本 .md 文件，附件以本地路径引用，体积小但脱离设备打不开图片。"
        case .markdown:
            return "目录形式：README.md + attachments/，附件随行，可直接拖到电脑/笔记软件。"
        case .pdf:
            return "A4 排版、按月分章的 PDF 时光书，适合打印或长期归档。"
        }
    }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case all
    case lastMonth
    case lastYear
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:       return "全部"
        case .lastMonth: return "最近一个月"
        case .lastYear:  return "最近一年"
        case .custom:    return "自定义"
        }
    }
}

private struct ExportedFile: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview {
    NavigationStack { ExportView() }
        .modelContainer(for: [Memory.self, Person.self], inMemory: true)
}
