import Alamofire
import Foundation
import Starscream

class IoBrokerAPI: WebSocketDelegate {
    static let shared = IoBrokerAPI()
    static var webSocket: WebSocket?
    static var webSocketCheck: WebSocket? // Temporärer WebSocket für die Überprüfung
    static var webSocketConnected: Bool = false
    static var webSocketCheckInProgress: Bool = false // Variable zum Verfolgen des Verbindungsstatus der temporären WebSocket
    static var webSocketMap: [ObjectIdentifier: UUID] = [:]
    static var reconnectAttempts = 0
    static var isReconnecting = false
    static var reconnectTimer: Timer?
    static var completionHandlers: [UUID: (Bool, String) -> Void] = [:]
    static var temporaryCompletionHandler: ((Bool, String) -> Void)? // Neuer Completion-Handler
    static var messageQueue: [UUID: [String: (message: [String: Any], completion: (Bool) -> Void)]] = [:]

    // Neue statische Variablen für die Zugangsdaten
    static var username: String = ""
    static var password: String = ""

    // Utility function to convert dictionary to JSON string
    static func toJSONString(_ dictionary: [String: Any]) -> String? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }

    // WebSocket methods
    static func connectWebSocket(id: UUID) {
        guard let settings = getSettings(for: id) else { return }
        var urlString = settings.url
        if urlString.hasPrefix("http://") {
            urlString = String(urlString.dropFirst(7))
        } else if urlString.hasPrefix("https://") {
            urlString = String(urlString.dropFirst(8))
        }
        let request = URLRequest(url: URL(string: "ws://\(urlString):\(settings.port)/socket")!)

        webSocket = WebSocket(request: request)
        webSocket?.delegate = IoBrokerAPI.shared
        if let webSocket = webSocket {
            webSocketMap[ObjectIdentifier(webSocket)] = id
        }
        print("Attempting to connect to WebSocket at ws://\(urlString):\(settings.port)/socket")
        webSocket?.connect()
    }

    static func connectWebSocketCheck(urlString: String, port: String, username: String, password: String) {
        // Verhindern, dass eine neue Verbindung aufgebaut wird, wenn bereits eine in Arbeit ist
        guard !webSocketCheckInProgress else { return }

        self.username = username
        self.password = password
        
        var urlString = urlString
        if urlString.hasPrefix("http://") {
            urlString = String(urlString.dropFirst(7))
        } else if urlString.hasPrefix("https://") {
            urlString = String(urlString.dropFirst(8))
        }
        
        let request = URLRequest(url: URL(string: "ws://\(urlString):\(port)/socket")!)
        webSocketCheck = WebSocket(request: request)
        webSocketCheck?.delegate = IoBrokerAPI.shared
        print("Attempting to connect to WebSocket at ws://\(urlString):\(port)/socket for check")
        webSocketCheckInProgress = true // Verbindungsstatus auf "in Arbeit" setzen
        webSocketCheck?.connect()
    }

    static func disconnectWebSocket() {
        webSocket?.disconnect()
        webSocket = nil
        webSocketConnected = false
        print("WebSocket disconnected")
    }

    static func disconnectWebSocketCheck() {
        webSocketCheck?.disconnect()
        webSocketCheck = nil
        webSocketCheckInProgress = false // Verbindungsstatus zurücksetzen
        print("Temporary WebSocket disconnected")
    }

    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        guard let requestId = IoBrokerAPI.webSocketMap[ObjectIdentifier(client)] else {
            if client === IoBrokerAPI.webSocketCheck {
                handleWebSocketCheckEvent(event)
            }
            return
        }

        switch event {
        case .connected(let headers):
            IoBrokerAPI.webSocketConnected = true
            IoBrokerAPI.reconnectAttempts = 0
            IoBrokerAPI.isReconnecting = false
            IoBrokerAPI.reconnectTimer?.invalidate()
            IoBrokerAPI.reconnectTimer = nil
            print("WebSocket connected: \(headers)")
            IoBrokerAPI.updateSystemOnlineState(id: requestId, isOnline: true)

            // Send device token after connection
            if let deviceToken = SensorManager.shared.sensorValues["deviceToken"] as? String,
               let settings = IoBrokerAPI.getSettings(for: requestId) {
                IoBrokerAPI.sendDeviceToken(id: requestId, deviceToken: deviceToken, person: settings.person, device: settings.device) { success in
                    if success {
                        print("Device Token erfolgreich gesendet für System: \(settings.name)")
                    } else {
                        print("Fehler beim Senden des Device Tokens für System: \(settings.name)")
                    }
                }
            }
            IoBrokerAPI.sendCachedMessages(id: requestId)
        case .disconnected(let reason, let code):
            IoBrokerAPI.webSocketConnected = false
            print("WebSocket disconnected: \(reason) with code: \(code)")
            IoBrokerAPI.updateSystemOnlineState(id: requestId, isOnline: false)
            IoBrokerAPI.reconnectWebSocket(id: requestId)
        case .text(let text):
            print("Received text: \(text)") // Log every received message
            IoBrokerAPI.handleWebSocketMessage(text)
        case .binary(let data):
            print("Received binary data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            IoBrokerAPI.webSocketConnected = false
            print("WebSocket connection cancelled")
            IoBrokerAPI.updateSystemOnlineState(id: requestId, isOnline: false)
            IoBrokerAPI.reconnectWebSocket(id: requestId)
        case .error(let error):
            IoBrokerAPI.webSocketConnected = false
            if let error = error {
                print("WebSocket error: \(error)")
            }
            IoBrokerAPI.updateSystemOnlineState(id: requestId, isOnline: false)
            IoBrokerAPI.reconnectWebSocket(id: requestId)
        case .peerClosed:
            IoBrokerAPI.webSocketConnected = false
            print("WebSocket connection closed by peer")
            IoBrokerAPI.updateSystemOnlineState(id: requestId, isOnline: false)
        }
    }

    private func handleWebSocketCheckEvent(_ event: Starscream.WebSocketEvent) {
        switch event {
        case .connected(let headers):
            print("Temporary WebSocket connected: \(headers)")
            // Die richtigen Zugangsdaten einfügen
            if let url = IoBrokerAPI.webSocketCheck?.request.url?.host, let port = IoBrokerAPI.webSocketCheck?.request.url?.port {
                IoBrokerAPI.checkOnlineState(url: url, port: "\(port)", username: IoBrokerAPI.username, password: IoBrokerAPI.password) { success, message in
                    if success {
                        print("Online state checked successfully: \(message)")
                    } else {
                        print("Failed to check online state: \(message)")
                    }
                    IoBrokerAPI.disconnectWebSocketCheck()
                }
            }
        case .disconnected(let reason, let code):
            print("Temporary WebSocket disconnected: \(reason) with code: \(code)")
            IoBrokerAPI.disconnectWebSocketCheck() // Verbindungsstatus zurücksetzen
        case .text(let text):
            print("Received text on temporary WebSocket: \(text)")
            IoBrokerAPI.handleWebSocketMessage(text)
        case .binary(let data):
            print("Received binary data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            print("Temporary WebSocket connection cancelled")
            IoBrokerAPI.disconnectWebSocketCheck() // Verbindungsstatus zurücksetzen
        case .error(let error):
            if let error = error {
                print("Temporary WebSocket error: \(error)")
            }
            IoBrokerAPI.disconnectWebSocketCheck() // Verbindungsstatus zurücksetzen
        case .peerClosed:
            print("Temporary WebSocket connection closed by peer")
            IoBrokerAPI.disconnectWebSocketCheck() // Verbindungsstatus zurücksetzen
        }
    }

    static func handleWebSocketMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let action = json["action"] as? String else { return }

        print("check Event \(json)")
        switch action {
        case "onlineState":
            if let data = json["data"] as? [String: Any], let locationString = data["location"] as? String, let online = data["online"] as? Bool, online {
                callTemporaryCompletionHandler(success: true, message: locationString)
            } else if let error = json["error"] as? String {
                callTemporaryCompletionHandler(success: false, message: error)
            } else {
                callTemporaryCompletionHandler(success: false, message: "Unknown error")
            }
        case "getPersons":
            print("Received getPersons response: \(json)")
            if let persons = json["data"] as? [[String: Any]] {
                let personNames = persons.compactMap { $0["person"] as? String }
                callTemporaryCompletionHandler(success: true, message: personNames.joined(separator: ","))
            } else if let error = json["error"] as? String {
                callTemporaryCompletionHandler(success: false, message: error)
            }
        case "getDevices":
            print("response getDevices \(json)")
            if let devices = json["data"] as? [[String: Any]] {
                let deviceNames = devices.compactMap { $0["device"] as? String }
                callCompletionHandler(action: action, success: true, message: deviceNames.joined(separator: ","))
            } else if let error = json["error"] as? String {
                callCompletionHandler(action: action, success: false, message: error)
            }
        case "notification":
            print("notification \(json)")
            NotificationController.shared.handleNotification(json)
        default:
            break
        }
    }

    static func callCompletionHandler(action: String, success: Bool, message: String) {
        if let handler = completionHandlers.removeValue(forKey: UUID()) {
            handler(success, message)
        }
    }

    static func callTemporaryCompletionHandler(success: Bool, message: String) {
        if let handler = temporaryCompletionHandler {
            print("callTemporaryCompletionHandler: success=\(success), message=\(message)")
            handler(success, message)
            temporaryCompletionHandler = nil // Handler zurücksetzen, um Mehrfachaufrufe zu vermeiden
        }
    }

    static func sendDeviceToken(id: UUID, deviceToken: String, person: String, device: String, completion: @escaping (Bool) -> Void) {
        guard let settings = getSettings(for: id) else {
            completion(false)
            return
        }
        let message: [String: Any] = [
            "action": "setDeviceToken",
            "clientId": id.uuidString,
            "username": settings.username,
            "password": settings.password,
            "data": [
                "deviceToken": deviceToken,
                "person": person,
                "device": device
            ]
        ]

        webSocket?.write(string: toJSONString(message) ?? "", completion: {
            completion(true)
        })
    }

    static func sendNotificationAcknowledgment(_ json: [String: Any], for webSocketId: ObjectIdentifier) {
        guard let settings = IoBrokerAPI.getSettings(for: IoBrokerAPI.webSocketMap[webSocketId]!) else {
            print("Settings not found for acknowledgment")
            return
        }

        let acknowledgmentMessage: [String: Any] = [
            "action": "notificationAck",
            "username": settings.username,
            "password": settings.password,
            "data": json
        ]

        if let jsonString = IoBrokerAPI.toJSONString(acknowledgmentMessage) {
            IoBrokerAPI.webSocket?.write(string: jsonString)
        }
    }

    static func checkOnlineState(url: String, port: String, username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        connectWebSocketCheck(urlString: url, port: port, username: username, password: password)
        let message: [String: Any] = [
            "action": "onlineState",
            "username": username,
            "password": password
        ]
        if let jsonString = toJSONString(message) {
            print("webSocketCheck \(message)")
            webSocketCheck?.write(string: jsonString)
        }
        temporaryCompletionHandler = { success, location in
            if success {
                fetchPersons(url: url, port: port, username: username, password: password) { success, message in
                    completion(success, location)
                    if success {
                        print("Fetched persons successfully: \(message)")
                    } else {
                        print("Failed to fetch persons: \(message)")
                    }
                    // WebSocket-Verbindung erst nach der gesamten Verarbeitung schließen
                    IoBrokerAPI.disconnectWebSocketCheck()
                }
            } else {
                completion(success, location)
                IoBrokerAPI.disconnectWebSocketCheck()
            }
        }
    }

    static func fetchPersons(url: String, port: String, username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        print("fetchPersons")
        let message: [String: Any] = [
            "action": "getPersons",
            "username": username,
            "password": password
        ]
        if let jsonString = toJSONString(message) {
            webSocketCheck?.write(string: jsonString)
        }
        temporaryCompletionHandler = completion
    }

    static func fetchDevices(url: String, port: String, username: String, password: String, person: String, completion: @escaping (Bool, String) -> Void) {
        print("fetchDevices")
        let message: [String: Any] = [
            "action": "getDevices",
            "username": username,
            "password": password,
            "data": ["person": person]
        ]
        if let jsonString = toJSONString(message) {
            webSocketCheck?.write(string: jsonString)
        }
        temporaryCompletionHandler = completion
    }

    static func createUser(url: String, port: String, username: String, password: String, person: String, completion: @escaping (Bool) -> Void) {
        let message: [String: Any] = [
            "action": "postPersons",
            "username": username,
            "password": password,
            "data": ["person": person]
        ]
        if let jsonString = toJSONString(message) {
            webSocketCheck?.write(string: jsonString, completion: {
                completion(true)
            })
        }
    }

    static func createDevice(url: String, port: String, username: String, password: String, person: String, device: String, completion: @escaping (Bool) -> Void) {
        let message: [String: Any] = [
            "action": "postDevices",
            "username": username,
            "password": password,
            "data": ["person": person, "device": device, "sensors": DefaultSensors.toCreateDeviceSensors()]
        ]
        if let jsonString = toJSONString(message) {
            webSocketCheck?.write(string: jsonString, completion: {
                completion(true)
            })
        }
    }

    static func postSensorData(for person: String, device: String, sensor: String, data: Any, id: UUID, completion: @escaping (Bool) -> Void) {
        guard let settings = getSettings(for: id) else {
            completion(false)
            updateSystemOnlineState(id: id, isOnline: false)
            return
        }
        let message: [String: Any] = [
            "action": "set",
            "username": settings.username,
            "password": settings.password,
            "data": [
                "path": "person.\(person).\(device).\(sensor)",
                "value": data
            ]
        ]
        if webSocketConnected {
            webSocket?.write(string: toJSONString(message) ?? "", completion: {
                completion(true)
            })
        } else {
            cacheMessage(id: id, sensor: sensor, message: message, completion: completion)
        }
    }

    static func setPresence(id: UUID, locationName: String, person: String, presence: Bool, completion: @escaping (Bool) -> Void) {
        guard let settings = getSettings(for: id) else {
            completion(false)
            return
        }
        let message: [String: Any] = [
            "action": "setPresence",
            "username": settings.username,
            "password": settings.password,
            "data": [
                "locationName": locationName,
                "person": person,
                "presence": presence
            ]
        ]
        if webSocketConnected {
            webSocket?.write(string: toJSONString(message) ?? "", completion: {
                completion(true)
            })
        } else {
            cacheMessage(id: id, sensor: "presence_\(locationName)_\(person)", message: message, completion: completion)
        }
    }

    static func setDistance(id: UUID, locationName: String, person: String, distance: Double, completion: @escaping (Bool) -> Void) {
        guard let settings = getSettings(for: id) else {
            completion(false)
            return
        }
        let message: [String: Any] = [
            "action": "setPresence",
            "username": settings.username,
            "password": settings.password,
            "data": [
                "locationName": locationName,
                "person": person,
                "distance": distance
            ]
        ]
        if webSocketConnected {
            webSocket?.write(string: toJSONString(message) ?? "", completion: {
                completion(true)
            })
        } else {
            cacheMessage(id: id, sensor: "distance_\(locationName)_\(person)", message: message, completion: completion)
        }
    }

    static func checkTagExists(tagID: String, completion: @escaping (Bool) -> Void) {
        let systems = SettingsManager.shared.loadSettings().filter { $0.isActive }
        
        guard !systems.isEmpty else {
            completion(false)
            return
        }
        
        var successCount = 0
        
        for system in systems {
            let message: [String: Any] = [
                "action": "tagsTrigger",
                "username": system.username,
                "password": system.password,
                "data": ["tagId": tagID]
            ]
            
            if webSocketConnected {
                webSocket?.write(string: toJSONString(message) ?? "", completion: {
                    successCount += 1
                    if successCount == systems.count {
                        completion(true)
                    }
                })
            } else {
                completion(false)
                return
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if successCount < systems.count {
                completion(false)
            }
        }
    }

    static func createTag(tagID: String, name: String, completion: @escaping (Bool) -> Void) {
        let systems = SettingsManager.shared.loadSettings().filter { $0.isActive }
        
        guard !systems.isEmpty else {
            completion(false)
            return
        }
        
        var successCount = 0
        var failureCount = 0
        
        for system in systems {
            let message: [String: Any] = [
                "action": "createTag",
                "username": system.username,
                "password": system.password,
                "data": [
                    "tagId": tagID,
                    "name": name
                ]
            ]
            
            if webSocketConnected {
                webSocket?.write(string: toJSONString(message) ?? "", completion: {
                    successCount += 1
                    if successCount == systems.count {
                        completion(true)
                    }
                })
            } else {
                cacheMessage(id: system.id, sensor: "tag_\(tagID)", message: message, completion: completion)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if failureCount == systems.count {
                completion(false)
            }
        }
    }

    private static func updateSystemOnlineState(id: UUID, isOnline: Bool) {
        if var system = getSettings(for: id) {
            system.onlineState = isOnline
            SettingsManager.shared.saveSettings(system)
        }
    }

    static func reconnectWebSocket(id: UUID) {
        guard let settings = getSettings(for: id) else { return }

        if IoBrokerAPI.isReconnecting { return }

        IoBrokerAPI.isReconnecting = true
        IoBrokerAPI.reconnectAttempts = 0
        
        func scheduleReconnect() {
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                if !IoBrokerAPI.webSocketConnected {
                    IoBrokerAPI.connectWebSocket(id: id)
                    IoBrokerAPI.reconnectAttempts += 1
                }
                if !IoBrokerAPI.webSocketConnected{
                    scheduleReconnect()
                } else {
                    IoBrokerAPI.isReconnecting = false
                }
            }
        }

        scheduleReconnect()
    }

    static func checkWebSocketConnection(id: UUID) {
        if webSocket == nil || !webSocketConnected {
            reconnectWebSocket(id: id)
        }
    }
    
    static func checkAllWebSocketConnections() {
        let systems = SettingsManager.shared.loadSettings()
        for system in systems {
            if system.isActive {
                reconnectWebSocket(id: system.id)
            }
        }
    }

    private static func getSettings(for id: UUID) -> IoBrokerSettings? {
        return SettingsManager.shared.loadSettings().first(where: { $0.id == id })
    }

    private static func cacheMessage(id: UUID, sensor: String, message: [String: Any], completion: @escaping (Bool) -> Void) {
        if messageQueue[id] == nil {
            messageQueue[id] = [:]
        }
        messageQueue[id]?[sensor] = (message, completion)
        print("Message cached for sensor: \(sensor)")
    }

    private static func sendCachedMessages(id: UUID) {
        guard let messages = messageQueue[id] else { return }

        for (sensor, (message, completion)) in messages {
            webSocket?.write(string: toJSONString(message) ?? "", completion: {
                completion(true)
            })
        }
        messageQueue[id]?.removeAll()
    }
}
