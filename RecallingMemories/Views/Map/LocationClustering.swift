//
//  LocationClustering.swift
//  拾忆
//
//  按经纬度聚类记忆 — 同一地点的多条记忆合并为一个图钉
//

import Foundation
import CoreLocation

struct LocationCluster: Identifiable, Hashable {
    let id: UUID = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let memories: [Memory]

    /// 该 cluster 时间跨度的人话描述（"今天" / "上周" / "2024-3 → 2024-7"）
    var dateRangeDescription: String {
        guard let first = memories.first?.createdAt,
              let last = memories.last?.createdAt else { return "" }
        let earlier = min(first, last)
        let later = max(first, last)

        let cal = Calendar.current
        if cal.isDate(earlier, inSameDayAs: later) {
            return earlier.formatted(.dateTime.year().month().day())
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy/M/d"
        return "\(f.string(from: earlier)) – \(f.string(from: later))"
    }

    static func == (lhs: LocationCluster, rhs: LocationCluster) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum LocationClustering {

    /// 把记忆按地理位置聚类。
    /// - 经纬度四舍五入到 4 位小数（约 11 米）作为 bucket key
    /// - 优先用 POI 名称（locationName）合并；同名同区域视为同点
    static func cluster(_ memories: [Memory]) -> [LocationCluster] {
        struct Key: Hashable {
            let lat: Double
            let lon: Double
            let name: String
        }

        var buckets: [Key: [Memory]] = [:]
        for memory in memories {
            guard let lat = memory.latitude, let lon = memory.longitude else { continue }
            let key = Key(
                lat: (lat * 10_000).rounded() / 10_000,
                lon: (lon * 10_000).rounded() / 10_000,
                name: memory.locationName ?? ""
            )
            buckets[key, default: []].append(memory)
        }

        return buckets.map { key, items in
            // 用 bucket 内的平均坐标作为图钉位置（更稳定）
            let avgLat = items.compactMap(\.latitude).reduce(0, +) / Double(items.count)
            let avgLon = items.compactMap(\.longitude).reduce(0, +) / Double(items.count)
            let title = items.first?.locationName?.isEmpty == false
                ? items.first!.locationName!
                : String(format: "%.4f, %.4f", avgLat, avgLon)
            return LocationCluster(
                coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                title: title,
                memories: items.sorted { $0.createdAt > $1.createdAt }
            )
        }
        .sorted { $0.memories.count > $1.memories.count }
    }
}
