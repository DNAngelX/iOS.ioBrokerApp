import Foundation
import Starscream

class AddSystemController: WebSocketDelegate {
    static var webSocketCheck: WebSocket?
    static var temporaryCompletionHandler: ((Bool, String) -> Void)?
    static var isWebSocketCheckConnected: Bool = false // Zustand der WebSocket-Verbindung

    static func connectWebSocketCheck(urlString: String, port: String, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: URL(string: "ws://\(urlString):\(port)/socket")!)
        webSocketCheck = WebSocket(request: request)
        webSocketCheck?.delegate = AddSystemController.shared
        webSocketCheck?.connect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if isWebSocketCheckConnected {
                completion(true)
            } else {
                completion(false)
                webSocketCheck?.disconnect()
                webSocketCheck = nil
            }
        }
    }

    static func checkWebSocketCredentials(url: String, port: String, username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        let message: [String: Any] = [
            "action": "onlineState",
            "username": username,
            "password": password
        ]
        if let jsonString = toJSONString(message) {
            print("webSocketCheck \(message)")
            webSocketCheck?.write(string: jsonString)
        }
        temporaryCompletionHandler = completion
    }
    
    static func disconnectWebSocketCheck() {
            webSocketCheck?.disconnect()
            webSocketCheck = nil
            print("Temporary WebSocket disconnected")
        }

    static func fetchPersons(url: String, port: String, username: String, password: String, completion: @escaping (Bool, String) -> Void) {
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
            print("createDevice \(message)")
            webSocketCheck?.write(string: jsonString, completion: {
                completion(true)
            })
        }
    }

    static func toJSONString(_ dictionary: [String: Any]) -> String? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }

    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("Temporary WebSocket connected: \(headers)")
            AddSystemController.isWebSocketCheckConnected = true
        case .disconnected(let reason, let code):
            print("Temporary WebSocket disconnected: \(reason) with code: \(code)")
            AddSystemController.isWebSocketCheckConnected = false
            AddSystemController.webSocketCheck = nil
        case .text(let text):
            AddSystemController.handleWebSocketMessage(text)
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
            AddSystemController.isWebSocketCheckConnected = false
            AddSystemController.webSocketCheck = nil
        case .error(let error):
            if let error = error {
                print("Temporary WebSocket error: \(error)")
            }
            AddSystemController.isWebSocketCheckConnected = false
            AddSystemController.webSocketCheck = nil
        case .peerClosed:
            print("Temporary WebSocket connection closed by peer")
            AddSystemController.isWebSocketCheckConnected = false
            AddSystemController.webSocketCheck = nil
        }
    }

    static func handleWebSocketMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            if let errorData = message.data(using: .utf8),
               let errorJson = try? JSONSerialization.jsonObject(with: errorData, options: []) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                callTemporaryCompletionHandler(success: false, message: errorMessage)
            }
            return
        }

        guard let action = json["action"] as? String else {
            if let error = json["error"] as? String {
                callTemporaryCompletionHandler(success: false, message: error)
            }
            return
        }

        switch action {
        case "onlineState":
            print("check Event \(json)")
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
                callTemporaryCompletionHandler(success: true, message: deviceNames.joined(separator: ","))
            } else if let error = json["error"] as? String {
                callTemporaryCompletionHandler(success: false, message: error)
            }
        default:
            break
        }
    }

    static func callTemporaryCompletionHandler(success: Bool, message: String) {
        if let handler = temporaryCompletionHandler {
            handler(success, message)
            temporaryCompletionHandler = nil // Handler zurücksetzen, um Mehrfachaufrufe zu vermeiden
        }
    }

    private static let shared = AddSystemController() // Singleton-Instanz für Delegate
}
