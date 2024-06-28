import Foundation

class SettingsManager {
    static let shared = SettingsManager()

    private let settingsKey = "ioBrokerSettings"

    func saveSettings(_ settings: IoBrokerSettings) {
        var currentSettings = loadSettings()
        if let index = currentSettings.firstIndex(where: { $0.id == settings.id }) {
            currentSettings[index] = settings
        } else {
            currentSettings.append(settings)
        }
        if let data = try? JSONEncoder().encode(currentSettings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    func loadSettings() -> [IoBrokerSettings] {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode([IoBrokerSettings].self, from: data) {
            return settings
        }
        return []
    }

    func clearSettings() {
        UserDefaults.standard.removeObject(forKey: settingsKey)
    }

    func deleteSettings(_ settings: IoBrokerSettings) {
        var currentSettings = loadSettings()
        currentSettings.removeAll { $0.id == settings.id }
        if let data = try? JSONEncoder().encode(currentSettings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
}
