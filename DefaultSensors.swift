import Foundation

struct DefaultSensors {
    static let defaultSensors: [IoTSensor] = [
        IoTSensor(id: UUID(), name: "Aktivität", iconName: "figure.walk", value: "", isEnabled: true, deviceClass: "activity", iobrokerClass: "sensors.activity", type: "string"),
        IoTSensor(id: UUID(), name: "Durchschnittlicher aktiver Platz", iconName: "house", value: "", isEnabled: true, deviceClass: "averageActivePlace", iobrokerClass: "sensors.averageActivePlace", type: "string"),
        IoTSensor(id: UUID(), name: "Batteriestand", iconName: "battery.100", value: "", isEnabled: true, deviceClass: "batteryLevel", iobrokerClass: "sensors.battery_level", type: "number", unit: "%"),
        IoTSensor(id: UUID(), name: "Batteriestatus", iconName: "battery.100.bolt", value: "", isEnabled: true, deviceClass: "batteryState", iobrokerClass: "sensors.battery_state", type: "string"),
        IoTSensor(id: UUID(), name: "BSSID", iconName: "wifi", value: "", isEnabled: true, deviceClass: "bssid", iobrokerClass: "sensors.bssid", type: "string"),
        IoTSensor(id: UUID(), name: "Verbindungstyp", iconName: "antenna.radiowaves.left.and.right", value: "", isEnabled: true, deviceClass: "connectionType", iobrokerClass: "sensors.connection_type", type: "string"),
        IoTSensor(id: UUID(), name: "Router Distanz", iconName: "ruler", value: "", isEnabled: true, deviceClass: "distance", iobrokerClass: "sensors.distance", type: "number", unit: "m"),
        IoTSensor(id: UUID(), name: "Etagen aufgestiegen", iconName: "arrow.up", value: "", isEnabled: true, deviceClass: "floorsAscended", iobrokerClass: "sensors.floors_ascended", type: "number"),
        IoTSensor(id: UUID(), name: "Etagen abgestiegen", iconName: "arrow.down", value: "", isEnabled: true, deviceClass: "floorsDescended", iobrokerClass: "sensors.floors_descended", type: "number"),
        IoTSensor(id: UUID(), name: "Fokus", iconName: "moon", value: "", isEnabled: true, deviceClass: "focus", iobrokerClass: "sensors.focus", type: "string"),
        IoTSensor(id: UUID(), name: "Geokodierter Standort", iconName: "mappin.and.ellipse", value: "", isEnabled: true, deviceClass: "geocodedLocation", iobrokerClass: "sensors.geocoded_location", type: "string"),
        IoTSensor(id: UUID(), name: "Letzter Auslöser", iconName: "clock", value: "", isEnabled: true, deviceClass: "lastUpdateTrigger", iobrokerClass: "sensors.last_update_trigger", type: "string"),
        IoTSensor(id: UUID(), name: "SIM 1", iconName: "simcard", value: "", isEnabled: true, deviceClass: "sim1", iobrokerClass: "sensors.sim1", type: "string"),
        IoTSensor(id: UUID(), name: "SIM 2", iconName: "simcard.2", value: "", isEnabled: true, deviceClass: "sim2", iobrokerClass: "sensors.sim2", type: "string"),
        IoTSensor(id: UUID(), name: "SSID", iconName: "wifi", value: "", isEnabled: true, deviceClass: "ssid", iobrokerClass: "sensors.ssid", type: "string"),
        IoTSensor(id: UUID(), name: "Schritte", iconName: "figure.walk.circle", value: "", isEnabled: true, deviceClass: "steps", iobrokerClass: "sensors.steps", type: "number"),
        IoTSensor(id: UUID(), name: "Speicher", iconName: "internaldrive", value: "", isEnabled: true, deviceClass: "storage", iobrokerClass: "sensors.storage", type: "string", unit: "%"),
        IoTSensor(id: UUID(), name: "Länge", iconName: "location.north.line.fill", value: "", isEnabled: true, deviceClass: "longitude", iobrokerClass: "sensors.longitude", type: "number"),
        IoTSensor(id: UUID(), name: "Breite", iconName: "location.north.line.fill", value: "", isEnabled: true, deviceClass: "latitude", iobrokerClass: "sensors.latitude", type: "number"),
        IoTSensor(id: UUID(), name: "Verbindung", iconName: "network", value: "", isEnabled: true, deviceClass: "connection", iobrokerClass: "connection", type: "boolean", role: "indicator.connected")
    ]

    static func toCreateDeviceSensors() -> [[String: Any]] {
        return defaultSensors.map { sensor in
            var sensorDict: [String: Any] = ["name": sensor.iobrokerClass ?? "", "type": sensor.type]
            if let unit = sensor.unit {
                sensorDict["unit"] = unit
            }
            if let role = sensor.role {
                sensorDict["role"] = role
            }
            return sensorDict
        }
    }
}

