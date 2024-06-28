import Foundation

class SensorSettings {
    static let shared = SensorSettings()
    var updateInterval: Int {
        get {
            if let savedInterval = UserDefaults.standard.value(forKey: "updateInterval") as? Int {
                return savedInterval
            }
            return 300 // Default to 5 minutes
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "updateInterval")
        }
    }
    var availableIntervals: [Int: String] = [
        0: "Aus",
        10: "10 Sec",
        60: "1 Minute",
        300: "5 Minuten",
        600: "10 Minuten",
        1800: "30 Minuten",
        3600: "1 Stunde"
    ]
    
    func intervalLabel(for value: Int) -> String {
        return availableIntervals[value] ?? "Unbekannt"
    }
}
