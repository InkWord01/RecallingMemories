//
//  LocationService.swift
//  拾忆
//
//  CoreLocation 封装 — 单次定位 + POI 反编译
//

import Foundation
import CoreLocation

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published var currentLocation: CLLocation?
    @Published var currentPOI: String?

    private let manager = CLLocationManager()
    private var requestContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// 请求权限并获取一次当前位置
    func requestCurrentLocation() async throws -> CLLocation {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.requestContinuation = continuation
            manager.requestLocation()
        }
    }

    /// 反向地理编码：经纬度 → POI 名称
    func reverseGeocode(_ location: CLLocation) async throws -> String? {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location, preferredLocale: .current)
        guard let pm = placemarks.first else { return nil }
        // 优先使用 POI / 子地点名称，回退到行政区
        return pm.name ?? pm.subLocality ?? pm.locality
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.currentLocation = location
            self.requestContinuation?.resume(returning: location)
            self.requestContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.requestContinuation?.resume(throwing: error)
            self.requestContinuation = nil
        }
    }
}
