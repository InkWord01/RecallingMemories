//
//  MapView.swift
//  拾忆
//
//  足迹地图 — 聚类标注 + 点击图钉弹出该地点的记忆列表
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Query(sort: \Memory.createdAt, order: .reverse) private var memories: [Memory]

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedCluster: LocationCluster?

    /// 按地点聚类的记忆（key = 经纬度四舍五入到 4 位小数 ≈ 11m 精度）
    private var clusters: [LocationCluster] {
        LocationClustering.cluster(memories)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                if clusters.isEmpty {
                    EmptyStateView(
                        icon: "map",
                        title: "还没有足迹",
                        message: "记录时给个定位，这里就会浮出旅程的地图。",
                        primaryAction: ("去记录此刻", {
                            AppRouter.shared.requestedTab = .record
                        }),
                        secondaryHint: "已记录但没定位？检查系统设置中的位置权限"
                    )
                } else {
                    mapContent
                }
            }
            .navigationTitle("足迹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !clusters.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            recenter()
                        } label: {
                            Image(systemName: "scope")
                        }
                        .accessibilityLabel("聚焦所有足迹")
                    }
                }
            }
            .sheet(item: $selectedCluster) { cluster in
                ClusterDetailSheet(cluster: cluster)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var mapContent: some View {
        Map(position: $cameraPosition, selection: clusterSelectionBinding) {
            ForEach(clusters) { cluster in
                Annotation(
                    cluster.title,
                    coordinate: cluster.coordinate
                ) {
                    ClusterPin(count: cluster.memories.count, isSelected: selectedCluster?.id == cluster.id)
                        .accessibilityElement()
                        .accessibilityLabel("\(cluster.title)，\(cluster.memories.count) 条记忆")
                        .accessibilityAddTraits(.isButton)
                }
                .tag(cluster.id)
            }

            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }

    /// `Map(selection:)` 用 Hashable 做绑定，将选中的 id 反查回 cluster
    private var clusterSelectionBinding: Binding<UUID?> {
        Binding(
            get: { selectedCluster?.id },
            set: { id in
                selectedCluster = clusters.first { $0.id == id }
            }
        )
    }

    /// 重新让相机框选所有图钉
    private func recenter() {
        guard !clusters.isEmpty else { return }
        let coords = clusters.map(\.coordinate)
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.5,
            longitudeDelta: max(maxLon - minLon, 0.01) * 1.5
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

// MARK: - 自定义图钉

private struct ClusterPin: View {
    let count: Int
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.orange : Color.orange.opacity(0.85))
                .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

            if count > 1 {
                Text("\(count)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.white)
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Cluster 详情面板

private struct ClusterDetailSheet: View {
    let cluster: LocationCluster

    @State private var detailMemory: Memory?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                            .frame(width: 36, height: 36)
                            .background(.orange.opacity(0.15), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cluster.title)
                                .font(.headline)
                            Text("\(cluster.memories.count) 条记忆 · \(cluster.dateRangeDescription)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                Section("记忆") {
                    ForEach(cluster.memories) { memory in
                        Button {
                            detailMemory = memory
                        } label: {
                            ClusterMemoryRow(memory: memory)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("此地的记忆")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $detailMemory) { memory in
                MemoryDetailView(memory: memory)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

private struct ClusterMemoryRow: View {
    let memory: Memory

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 缩略图占位（首张附件 / 情绪 / 文字图标）
            thumbnail
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                if !memory.text.isEmpty {
                    Text(memory.text)
                        .font(.subheadline)
                        .lineLimit(2)
                }
                HStack(spacing: 6) {
                    Text(memory.createdAt, format: .dateTime.month().day().hour().minute())
                    if !memory.people.isEmpty {
                        Text("·")
                        Text(memory.people.prefix(2).map(\.name).joined(separator: "、"))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let first = memory.attachments.first,
           let img = loadImage(first) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else if let mood = memory.moodTag {
            ZStack {
                Color.orange.opacity(0.15)
                Text(mood).font(.title2)
            }
        } else {
            ZStack {
                Color.white.opacity(0.06)
                Image(systemName: "text.alignleft")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadImage(_ attachment: Attachment) -> UIImage? {
        guard let data = AttachmentStore.loadData(for: attachment) else { return nil }
        return UIImage(data: data)
    }
}

#Preview {
    MapView()
        .modelContainer(for: [Memory.self, Person.self, Attachment.self], inMemory: true)
}
