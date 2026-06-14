//
//  QuickRecordWidget.swift
//  RecallingMemoriesWidget
//
//  Quick Record — 一键打开记录页 + 显示总条数 + 最近一条预览
//

import WidgetKit
import SwiftUI

struct QuickRecordWidget: Widget {
    let kind = "QuickRecordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetSnapshotProvider()) { entry in
            QuickRecordWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(red: 0.10, green: 0.10, blue: 0.18),
                                 Color(red: 0.18, green: 0.12, blue: 0.24)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("快速记录")
        .description("点击直接打开拾忆，记录此刻的想法。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuickRecordWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        switch family {
        case .systemSmall: smallView
        default:           mediumView
        }
    }

    // MARK: - Small

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                Spacer()
                Text("\(entry.snapshot.totalCount)")
                    .font(.system(size: 24, weight: .bold, design: .serif))
            }
            .foregroundStyle(.white.opacity(0.9))

            Spacer()

            Text("此刻")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text("点一下，写下来")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))

            HStack {
                Spacer()
                Image(systemName: "square.and.pencil")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.white.opacity(0.18), in: Circle())
            }
        }
        .widgetURL(WidgetShared.DeepLink.record)
    }

    // MARK: - Medium

    private var mediumView: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧：记录入口
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("拾忆")
                        .font(.system(.callout, design: .serif).weight(.medium))
                }
                .foregroundStyle(.white.opacity(0.85))

                Spacer()

                Text("此刻")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                Text("\(entry.snapshot.totalCount) 条记忆")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                Link(destination: WidgetShared.DeepLink.record) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                        Text("记录")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2), in: Capsule())
                }
            }
            .frame(maxWidth: 120, alignment: .leading)

            Divider().background(.white.opacity(0.2))

            // 右侧：最近一条预览
            if let latest = entry.snapshot.latest {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(latest.createdAt, format: .dateTime.month().day().hour().minute())
                            .font(.caption2)
                        if let mood = latest.moodTag {
                            Text(mood).font(.caption)
                        }
                    }
                    .foregroundStyle(.white.opacity(0.6))

                    Text(latest.text.isEmpty ? "（仅媒体记录）" : latest.text)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .lineLimit(4)

                    if let location = latest.locationName {
                        Label(location, systemImage: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("还没有记忆")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("点左侧「记录」开始")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview(as: .systemSmall) {
    QuickRecordWidget()
} timeline: {
    SnapshotEntry(date: Date(), snapshot: .preview)
}

#Preview(as: .systemMedium) {
    QuickRecordWidget()
} timeline: {
    SnapshotEntry(date: Date(), snapshot: .preview)
}
