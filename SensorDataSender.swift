import Foundation

class SensorDataSender {
    static let shared = SensorDataSender()

    private init() {}

    func sendSensorDataToIoBroker() {
        let systems = SettingsManager.shared.loadSettings()
        var updatedSystems = systems

        for i in 0..<updatedSystems.count where updatedSystems[i].isActive {
            var updated = false
            for sensor in SensorManager.shared.sensors where sensor.isEnabled {
                if let value = SensorManager.shared.sensorValues[sensor.deviceClass ?? ""] {
                    let lastValue = updatedSystems[i].lastSensorValues[sensor.deviceClass ?? ""] as? String
                    let lastUpdate = updatedSystems[i].lastUpdateTimes[sensor.deviceClass ?? ""]

                    let currentTime = Date()
                    let shouldUpdate = lastValue != "\(value)" || (lastUpdate == nil || currentTime.timeIntervalSince(lastUpdate!) > 12 * 60 * 60)

                    if shouldUpdate {
                        IoBrokerAPI.postSensorData(for: updatedSystems[i].person, device: updatedSystems[i].device, sensor: sensor.iobrokerClass ?? "", data: value, id: updatedSystems[i].id) { success in
                            if success {
                                updatedSystems[i].lastSensorValues[sensor.deviceClass ?? ""] = "\(value)"
                                updatedSystems[i].lastUpdateTimes[sensor.deviceClass ?? ""] = Date()
                                updated = true
                                SettingsManager.shared.saveSettings(updatedSystems[i])
                            } else {
                                print("Failed to send data for sensor: \(sensor.name)")
                                updatedSystems[i].onlineState = false
                                SettingsManager.shared.saveSettings(updatedSystems[i])
                            }
                        }
                    }
                }
            }
            if updated {
                print("Sensor data updated for system: \(updatedSystems[i].name)")
            }
        }
    }
}
