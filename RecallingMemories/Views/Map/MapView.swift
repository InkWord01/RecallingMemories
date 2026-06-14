//
//  MapView.swift
//  拾忆
//
//  地图模式 — 在地图上查看足迹，点击图钉弹出记录卡片
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Query private var memories: [Memory]
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(memories.filter { $0.latitude != nil && $0.longitude != nil }) { memory in
                    if let lat = memory.latitude, let lon = memory.longitude {
                        Marker(memory.locationName ?? "记忆", coordinate: .init(latitude: lat, longitude: lon))
                            .tint(.orange)
                    }
                }
            }
            .navigationTitle("足迹")
        }
    }
}

#Preview {
    MapView()
        .modelContainer(for: Memory.self, inMemory: true)
}
