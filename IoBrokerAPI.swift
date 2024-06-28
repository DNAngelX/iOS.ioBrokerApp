import Alamofire
import Foundation

class IoBrokerAPI {
    
    private static func getSettings(for id: UUID) -> IoBrokerSettings? {
        return SettingsManager.shared.loadSettings().first(where: { $0.id == id })
    }

    private static func constructURL(for id: UUID, path: String) -> String? {
        guard let settings = getSettings(for: id) else { return nil }
        var url = "\(settings.url):\(settings.port)\(path)"
        if settings.useCredentials {
            let credentials = "\(settings.username):\(settings.password)@"
            url = url.replacingOccurrences(of: "://", with: "://\(credentials)")
        }
        return url
    }

    static func checkOnlineStateWithoutSetting(url: String, port: String, useCredentials: Bool, username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        var fullURL = "\(url):\(port)/onlineState"
        if useCredentials {
            let credentials = "\(username):\(password)@"
            fullURL = fullURL.replacingOccurrences(of: "://", with: "://\(credentials)")
        }
        
        AF.request(fullURL).validate().responseJSON { response in
            print("Response: \(response)")
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any], let online = json["online"] as? Bool, let location = json["location"] as? String {
                    completion(online, location)
                } else {
                    completion(false, "")
                }
            case .failure(let error):
                print("Error: \(error)")
                completion(false, "")
            }
        }
    }

    static func fetchPersons(url: String, port: String, useCredentials: Bool, username: String, password: String, completion: @escaping ([String]) -> Void) {
        var fullURL = "\(url):\(port)/persons"
        if useCredentials {
            let credentials = "\(username):\(password)@"
            fullURL = fullURL.replacingOccurrences(of: "://", with: "://\(credentials)")
        }
        
        AF.request(fullURL).validate().responseDecodable(of: [[String: String]].self) { response in
            switch response.result {
            case .success(let personsArray):
                let persons = personsArray.compactMap { $0["person"] }
                completion(persons)
            case .failure:
                completion([])
            }
        }
    }

    static func fetchDevices(for person: String, url: String, port: String, useCredentials: Bool, username: String, password: String, completion: @escaping ([String]) -> Void) {
        var fullURL = "\(url):\(port)/persons/\(person)/devices"
        if useCredentials {
            let credentials = "\(username):\(password)@"
            fullURL = fullURL.replacingOccurrences(of: "://", with: "://\(credentials)")
        }
        
        AF.request(fullURL).validate().responseDecodable(of: [[String: String]].self) { response in
            switch response.result {
            case .success(let devicesArray):
                let devices = devicesArray.compactMap { $0["device"] }
                completion(devices)
            case .failure:
                completion([])
            }
        }
    }

    static func createUser(person: String, id: UUID, completion: @escaping (Bool) -> Void) {
        guard let url = constructURL(for: id, path: "/persons") else {
            completion(false)
            return
        }
        let parameters: [String: Any] = ["person": person]
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().response { response in
            completion(response.error == nil)
        }
    }

    static func createDevice(person: String, device: String, id: UUID, completion: @escaping (Bool) -> Void) {
        guard let url = constructURL(for: id, path: "/persons/\(person)/devices") else {
            print("Failed to construct URL")
            completion(false)
            return
        }
        let parameters: [String: Any] = [
            "device": device,
            "sensors": DefaultSensors.toCreateDeviceSensors()
        ]
        print("Creating device with URL: \(url) and parameters: \(parameters)")
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().response { response in
            if let error = response.error {
                print("Failed to create device: \(error.localizedDescription)")
            } else {
                print("Device created successfully")
            }
            completion(response.error == nil)
        }
    }

    static func postSensorData(for person: String, device: String, sensor: String, data: Any, id: UUID, completion: @escaping (Bool) -> Void) {
        let path = "/set/person.\(person).\(device).\(sensor)"
        guard let url = constructURL(for: id, path: path) else {
            completion(false)
            updateSystemOnlineState(id: id, isOnline: false)
            return
        }
        let parameters: [String: Any] = ["value": data]
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().response { response in
            let success = response.error == nil
            if !success {
                updateSystemOnlineState(id: id, isOnline: false)
            }
            completion(success)
        }
    }

    static func setPresence(id: UUID, locationName: String, person: String, presence: Bool, completion: @escaping (Bool) -> Void) {
        guard let url = constructURL(for: id, path: "/setPresence") else {
            completion(false)
            return
        }
        let parameters: [String: Any] = [
            "locationName": locationName,
            "person": person,
            "presence": presence
        ]
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().response { response in
            completion(response.error == nil)
        }
    }

    static func setDistance(id: UUID, locationName: String, person: String, distance: Double, completion: @escaping (Bool) -> Void) {
        guard let url = constructURL(for: id, path: "/setPresence") else {
            completion(false)
            return
        }
        let parameters: [String: Any] = [
            "locationName": locationName,
            "person": person,
            "distance": distance
        ]
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().response { response in
            completion(response.error == nil)
        }
    }

    private static func updateSystemOnlineState(id: UUID, isOnline: Bool) {
        if var system = getSettings(for: id) {
            system.onlineState = isOnline
            SettingsManager.shared.saveSettings(system)
        }
    }

    static func checkAllSystemsOnlineStatus() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            let systems = SettingsManager.shared.loadSettings()
            systems.forEach { system in
                checkOnlineStateWithoutSetting(url: system.url, port: system.port, useCredentials: system.useCredentials, username: system.username, password: system.password) { online, _ in
                    var updatedSystem = system
                    updatedSystem.onlineState = online
                    SettingsManager.shared.saveSettings(updatedSystem)
                }
            }
        }
    }
}
