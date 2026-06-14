//
//  OnThisDayWidget.swift
//  RecallingMemoriesWidget
//
//  那年今日 — 桌面上看到去年/前年的同一天写过什么
//

import WidgetKit
import SwiftUI

struct OnThisDayWidget: Widget {
    let kind = "OnThisDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetSnapshotProvider()) { entry in
            OnThisDayWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(red: 0.20, green: 0.14, blue: 0.10),
                                 Color(red: 0.36, green: 0.22, blue: 0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("那年今日")
        .description("看见过去同一天写下的想法。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct OnThisDayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        if let item = entry.snapshot.onThisDay {
            content(item: item)
                .widgetURL(WidgetShared.DeepLink.memory(item.id))
        } else {
            emptyView
                .widgetURL(WidgetShared.DeepLink.onThisDay)
        }
    }

    private func content(item: WidgetSnapshot.Item) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                Text(headerText(item))
                    .font(.caption.weight(.semibold))
                Spacer()
                if let mood = item.moodTag {
                    Text(mood).font(.callout)
                }
            }
            .foregroundStyle(.white.opacity(0.85))

            Text(item.text.isEmpty ? "（仅媒体记录）" : item.text)
                .font(family == .systemLarge
                      ? .system(size: 22, weight: .medium, design: .serif)
                      : .system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(family == .systemLarge ? 8 : 4)
                .lineSpacing(4)

            Spacer()

            HStack {
                if let location = item.locationName {
                    Label(location, systemImage: "location.fill")
                        .font(.caption2)
                }
                Spacer()
                Text(item.createdAt, format: .dateTime.year().month().day())
                    .font(.caption2)
            }
            .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                Text("那年今日")
                    .font(.caption.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.85))

            Spacer()

            Text("今天还没有过去的回忆")
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundStyle(.white)

            Text("一年后再来，会看到今天写下的痕迹。")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))

            Spacer()
        }
    }

    private func headerText(_ item: WidgetSnapshot.Item) -> String {
        if let years = item.yearsAgo, years >= 1 {
            return "\(years) 年前的今天"
        }
        let months = Calendar.current.dateComponents([.month], from: item.createdAt, to: Date()).month ?? 0
        return months >= 1 ? "\(months) 个月前的今天" : "今天的回忆"
    }
}

#Preview(as: .systemMedium) {
    OnThisDayWidget()
} timeline: {
    SnapshotEntry(date: Date(), snapshot: .preview)
}

#Preview(as: .systemLarge) {
    OnThisDayWidget()
} timeline: {
    SnapshotEntry(date: Date(), snapshot: .preview)
}
