import Foundation
import CoreLocation
import CoreMotion
import Network
import Combine
import UIKit
import SystemConfiguration.CaptiveNetwork
import CoreTelephony

class SensorManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = SensorManager()

    @Published var sensors: [IoTSensor] {
        didSet {
            if let data = try? JSONEncoder().encode(sensors) {
                UserDefaults.standard.set(data, forKey: "sensors")
            }
        }
    }

    var sensorValues: [String: Any] = [:]

    private var systems: [IoBrokerSettings] {
        SettingsManager.shared.loadSettings()
    }

    private let locationManager = CLLocationManager()
    private let motionActivityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    private let networkMonitor = NWPathMonitor()
    private var timer: Timer?

    override init() {
        if let data = UserDefaults.standard.data(forKey: "sensors"),
           let savedSensors = try? JSONDecoder().decode([IoTSensor].self, from: data) {
            self.sensors = savedSensors
        } else {
            self.sensors = DefaultSensors.defaultSensors
        }
        super.init()
        setupLocationManager()
        setupBatteryMonitoring()
        startMonitoringSensors()
    }

    func resetSensors() {
        self.sensors = DefaultSensors.defaultSensors
    }

    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters //kCLLocationAccuracyHundredMeters // Weniger genaue Standortaktualisierungen
        locationManager.distanceFilter = 35 // Nur Updates bei Bewegungen über 50 Meter
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        sensorValues["latitude"] = location.coordinate.latitude
        sensorValues["longitude"] = location.coordinate.longitude
        updateSensorValues()
    }

    func startMonitoringSensors() {
        if CMMotionActivityManager.isActivityAvailable() {
            motionActivityManager.startActivityUpdates(to: .main) { [weak self] activity in
                self?.updateActivity(activity)
            }
        }
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] data, error in
                self?.updatePedometerData(data)
            }
        }
        networkMonitor.start(queue: .main)
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.updateNetworkStatus(path)
        }
        startSendingDataAtIntervals()
        updateWiFiInfo()
        updateFocus()
        updateStorageInfo()
        updateAdditionalSensorValues()
    }

    func updateInterval(_ interval: Int) {
        SensorSettings.shared.updateInterval = interval
        startSendingDataAtIntervals()
    }

    private func getIntervalInSeconds() -> TimeInterval {
        return TimeInterval(SensorSettings.shared.updateInterval)
    }

    private func startSendingDataAtIntervals() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: getIntervalInSeconds(), repeats: true) { [weak self] _ in
            SensorDataSender.shared.sendSensorDataToIoBroker()
        }
    }

    private func updateActivity(_ activity: CMMotionActivity?) {
        guard let activity = activity else { return }
        if activity.walking {
            sensorValues["activity"] = "Walking"
        } else if activity.running {
            sensorValues["activity"] = "Running"
        } else if activity.cycling {
            sensorValues["activity"] = "Cycling"
        } else if activity.stationary {
            sensorValues["activity"] = "Stationary"
        } else {
            sensorValues["activity"] = "Unknown"
        }
        updateSensorValues()
    }

    private func updatePedometerData(_ data: CMPedometerData?) {
        guard let data = data else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        pedometer.queryPedometerData(from: startOfDay, to: now) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                self?.sensorValues["steps"] = data.numberOfSteps
                self?.sensorValues["floorsAscended"] = data.floorsAscended
                self?.sensorValues["floorsDescended"] = data.floorsDescended
                self?.sensorValues["distance"] = data.distance
                self?.updateSensorValues()
            }
        }
    }

    private func updateNetworkStatus(_ path: NWPath) {
        if path.status == .satisfied {
            sensorValues["connectionType"] = path.isExpensive ? "Cellular" : "Wi-Fi"
        } else {
            sensorValues["connectionType"] = "No Connection"
        }
        updateSensorValues()
    }

    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        sensorValues["batteryLevel"] = UIDevice.current.batteryLevel * 100
        sensorValues["batteryState"] = batteryStateToString(UIDevice.current.batteryState)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryStateDidChange), name: UIDevice.batteryStateDidChangeNotification, object: nil)
    }

    @objc private func batteryLevelDidChange(notification: NSNotification) {
        sensorValues["batteryLevel"] = UIDevice.current.batteryLevel * 100
        updateSensorValues()
    }

    @objc private func batteryStateDidChange(notification: NSNotification) {
        sensorValues["batteryState"] = batteryStateToString(UIDevice.current.batteryState)
        updateSensorValues()
    }

    private func batteryStateToString(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .charging:
            return "Charging"
        case .full:
            return "Full"
        case .unplugged:
            return "Unplugged"
        case .unknown:
            fallthrough
        @unknown default:
            return "Unknown"
        }
    }

    private func updateWiFiInfo() {
        if let interface = CNCopySupportedInterfaces() as? [String],
           let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interface.first! as CFString) as? [String: AnyObject] {
            sensorValues["ssid"] = unsafeInterfaceData["SSID"] as? String ?? "Unknown SSID"
            sensorValues["bssid"] = unsafeInterfaceData["BSSID"] as? String ?? "Unknown BSSID"
        }
        updateSensorValues()
    }

    private func updateFocus() {
        let currentFocusMode = "Default Focus" // Replace with actual focus detection logic
        sensorValues["focus"] = currentFocusMode
        updateSensorValues()
    }

    private func updateStorageInfo() {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        if let values = try? fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]) {
            let totalSpace = values.volumeTotalCapacity ?? 0
            let freeSpace = values.volumeAvailableCapacityForImportantUsage ?? 0
            let totalSpaceGB = Double(totalSpace) / (1024 * 1024 * 1024)
            let freeSpaceGB = Double(freeSpace) / (1024 * 1024 * 1024)
            let usedSpaceGB = totalSpaceGB - freeSpaceGB
            
            let totalSpaceGBRounded = round(totalSpaceGB * 10) / 10.0
            let freeSpaceGBRounded = round(freeSpaceGB * 10) / 10.0
            let usedPercentage = round((usedSpaceGB / totalSpaceGB) * 1000) / 10.0
            
            sensorValues["storage"] = "\(totalSpaceGBRounded) GB - \(freeSpaceGBRounded) GB free (\(usedPercentage)%)"
        }
        updateSensorValues()
    }

    private func updateAdditionalSensorValues() {
        if CMAltimeter.isRelativeAltitudeAvailable() {
            let barometer = CMAltimeter()
            barometer.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async {
                    self?.sensorValues["pressure"] = data.pressure.doubleValue
                    self?.updateSensorValues()
                }
            }
        }
        
        let screenBrightness = UIScreen.main.brightness
        DispatchQueue.main.async {
            self.sensorValues["screenBrightness"] = screenBrightness
        }
        
        let device = UIDevice.current
        sensorValues["deviceModel"] = device.model
        sensorValues["systemVersion"] = device.systemVersion
        
        updateSensorValues()
    }

    func updateSensor(_ sensor: IoTSensor) {
        var currentSensors = sensors
        if let index = currentSensors.firstIndex(where: { $0.id == sensor.id }) {
            currentSensors[index] = sensor
            sensors = currentSensors
        }
    }

    func updateSensorValues() {
        var valuesChanged = false
        for (key, value) in sensorValues {
            if let index = sensors.firstIndex(where: { $0.deviceClass == key }) {
                if sensors[index].value != "\(value)" {
                    sensors[index].value = "\(value)"
                    valuesChanged = true
                }
            }
        }
        if valuesChanged {
            logSensorValues()
        }
    }

    private func logSensorValues() {
        for (key, value) in sensorValues {
           // print("Sensor: \(key), Value: \(value)")
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        sensorValues["deviceToken"] = token
        updateSensorValues()
    }
}


struct IoTSensor: Identifiable, Codable {
    let id: UUID
    var name: String
    var iconName: String
    var value: String
    var isEnabled: Bool
    var deviceClass: String?
    var iobrokerClass: String?
    var type: String
    var unit: String?
    var role: String?
}
