import Foundation
import CoreLocation
import Combine
import SwiftUI

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = LocationManager()
    private var lastGeocodeUpdate: Date?
    
    @Published var currentLocation: CLLocation?
    @Published var zones: [Zone] {
        didSet {
            if let data = try? JSONEncoder().encode(zones) {
                UserDefaults.standard.set(data, forKey: "zones")
            }
        }
    }
    @Published var enterExitToggle: Bool {
        didSet {
            UserDefaults.standard.set(enterExitToggle, forKey: "enterExitToggle")
            configureLocationUpdates()
        }
    }
    @Published var backgroundUpdateToggle: Bool {
        didSet {
            UserDefaults.standard.set(backgroundUpdateToggle, forKey: "backgroundUpdateToggle")
            configureLocationUpdates()
        }
    }
    @Published var significantChangeToggle: Bool {
        didSet {
            UserDefaults.standard.set(significantChangeToggle, forKey: "significantChangeToggle")
            configureLocationUpdates()
        }
    }

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastLocationUpdate: Date?
    private var zoneStates: [UUID: Bool] = [:] // Track presence state for each zone
    private var lastDistanceUpdateTimes: [UUID: Date] = [:] // Track the last update time for each zone

    override init() {
        self.zones = UserDefaults.standard.data(forKey: "zones").flatMap { try? JSONDecoder().decode([Zone].self, from: $0) } ?? []
        self.enterExitToggle = UserDefaults.standard.bool(forKey: "enterExitToggle")
        self.backgroundUpdateToggle = UserDefaults.standard.bool(forKey: "backgroundUpdateToggle")
        self.significantChangeToggle = UserDefaults.standard.bool(forKey: "significantChangeToggle")
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        configureLocationUpdates()
    }
    
    private func configureLocationUpdates() {
        if backgroundUpdateToggle {
            locationManager.allowsBackgroundLocationUpdates = true
        } else {
            locationManager.allowsBackgroundLocationUpdates = false
        }

        if significantChangeToggle {
            locationManager.startMonitoringSignificantLocationChanges()
        } else {
            locationManager.stopMonitoringSignificantLocationChanges()
        }

        if enterExitToggle {
            for zone in zones {
                let region = CLCircularRegion(center: zone.location, radius: zone.radius, identifier: zone.id.uuidString)
                region.notifyOnEntry = true
                region.notifyOnExit = true
                locationManager.startMonitoring(for: region)
            }
        } else {
            for region in locationManager.monitoredRegions {
                locationManager.stopMonitoring(for: region)
            }
        }

        if !significantChangeToggle && !backgroundUpdateToggle {
            locationManager.stopUpdatingLocation()
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location

        let roundedLatitude = round(location.coordinate.latitude * 1_000_000) / 1_000_000
        let roundedLongitude = round(location.coordinate.longitude * 1_000_000) / 1_000_000

        let roundedLocation = "\(roundedLatitude), \(roundedLongitude)"

        if let lastLocation = SensorManager.shared.sensorValues["location"] as? String, lastLocation != roundedLocation {
            updateGeocodedLocation(location: location)
        }

        SensorManager.shared.sensorValues["location"] = roundedLocation
        SensorManager.shared.sensorValues["latitude"] = roundedLatitude
        SensorManager.shared.sensorValues["longitude"] = roundedLongitude

        SensorManager.shared.updateSensorValues()
        updateZoneDistances()
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            let location = CLLocation(latitude: circularRegion.center.latitude, longitude: circularRegion.center.longitude)
            updateGeocodedLocation(location: location)
            handleZoneChange(for: circularRegion, entered: true)
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            let location = CLLocation(latitude: circularRegion.center.latitude, longitude: circularRegion.center.longitude)
            updateGeocodedLocation(location: location)
            handleZoneChange(for: circularRegion, entered: false)
        }
    }

    private func handleZoneChange(for region: CLCircularRegion, entered: Bool) {
        guard let zoneIndex = zones.firstIndex(where: { $0.id.uuidString == region.identifier }) else { return }
        let zone = zones[zoneIndex]

        for system in SettingsManager.shared.loadSettings() where system.isActive {
            let presenceStateKey = "\(system.id.uuidString)-\(zone.id.uuidString)"
            
            if entered {
                // Set presence to true if we have entered the zone
                if zoneStates[zone.id] == false || zoneStates[zone.id] == nil {
                    IoBrokerAPI.setPresence(id: system.id, locationName: zone.name, person: system.person, presence: true) { success in
                        if success {
                            self.zoneStates[zone.id] = true
                        } else {
                            print("Failed to set presence for zone \(zone.name)")
                        }
                    }
                }
            } else {
                // Set presence to false if we have exited the zone
                IoBrokerAPI.setPresence(id: system.id, locationName: zone.name, person: system.person, presence: false) { success in
                    if success {
                        self.zoneStates[zone.id] = false
                    } else {
                        print("Failed to set presence for zone \(zone.name)")
                    }
                }
            }
        }
    }

    private func updateZoneDistances() {
        guard let currentLocation = currentLocation else { return }

        let interval = TimeInterval(SensorSettings.shared.updateInterval)

        for index in zones.indices {
            let zone = zones[index]
            let zoneLocation = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
            let distance = currentLocation.distance(from: zoneLocation)
            let roundedDistance = distance < 6 ? 0 : round(distance)

            if zone.distance != roundedDistance {
                zones[index].distance = roundedDistance

                for system in SettingsManager.shared.loadSettings() where system.isActive {
                    let lastUpdate = lastDistanceUpdateTimes[zone.id] ?? .distantPast

                    if Date().timeIntervalSince(lastUpdate) >= interval {
                        IoBrokerAPI.setDistance(id: system.id, locationName: zone.name, person: system.person, distance: roundedDistance) { success in
                            if success {
                                self.lastDistanceUpdateTimes[zone.id] = Date()
                            } else {
                                print("Failed to set distance for zone \(zone.name)")
                            }
                        }
                    }
                }
            }
        }
    }

    private func updateGeocodedLocation(location: CLLocation) {
        let roundedLatitude = round(location.coordinate.latitude * 100000) / 100000
        let roundedLongitude = round(location.coordinate.longitude * 100000) / 100000
        let newRoundedLocation = "\(roundedLatitude), \(roundedLongitude)"

        if let lastLocation = SensorManager.shared.sensorValues["location"] as? String, lastLocation == newRoundedLocation {
            return
        }
        
        // Check if the last update was less than 20 seconds ago
        if let lastUpdate = lastGeocodeUpdate, Date().timeIntervalSince(lastUpdate) < 20 {
            return
        }

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, error == nil else { return }
            if let placemark = placemarks?.first {
                SensorManager.shared.sensorValues["geocodedLocation"] = placemark.formattedAddress
                SensorManager.shared.updateSensorValues()
            }
        }
        
        // Update the last geocode update time
        lastGeocodeUpdate = Date()
    }

    func addZonesToSystem(_ system: IoBrokerSettings) {
        for zone in zones {
            if zone.isActive {
                let region = CLCircularRegion(center: zone.location, radius: zone.radius, identifier: zone.id.uuidString)
                region.notifyOnEntry = true
                region.notifyOnExit = true
                locationManager.startMonitoring(for: region)
            }
        }
    }
}

struct Zone: Identifiable, Codable {
    var id = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double
    var isActive: Bool
    var distance: Double? // Adding distance property

    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude
        case longitude
        case radius
        case isActive
        case distance // Adding distance to CodingKeys
    }

    init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double, radius: Double, isActive: Bool, distance: Double? = nil) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.isActive = isActive
        self.distance = distance
    }
}

extension CLPlacemark {
    var formattedAddress: String? {
        if let name = name, let locality = locality, let administrativeArea = administrativeArea {
            return "\(name), \(locality), \(administrativeArea)"
        } else {
            return nil
        }
    }
}
