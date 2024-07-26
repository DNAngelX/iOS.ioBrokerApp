import SwiftUI

struct DebugView: View {
    @State private var url: String = ""
    @State private var port: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var person: String = ""
    @State private var device: String = ""
    @State private var result: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Group {
                    TextField("URL", text: $url)
                    TextField("Port", text: $port)
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                    TextField("Person", text: $person)
                    TextField("Device", text: $device)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

                Button("Check WebSocket Connection") {
                    AddSystemController.connectWebSocketCheck(urlString: url, port: port) { success in
                        DispatchQueue.main.async {
                            if success {
                                result = "WebSocket connection successful"
                            } else {
                                result = "WebSocket connection failed"
                            }
                        }
                    }
                }
                .padding(.vertical, 5)

                Button("Check Online State") {
                    AddSystemController.checkWebSocketCredentials(url: url, port: port, username: username, password: password) { success, message in
                        DispatchQueue.main.async {
                            if success {
                                result = "Online: \(message)"
                            } else {
                                result = "Failed: \(message)"
                            }
                        }
                    }
                }
                .padding(.vertical, 5)

                Button("Fetch Persons") {
                    AddSystemController.fetchPersons(url: url, port: port, username: username, password: password) { success, message in
                        DispatchQueue.main.async {
                            if success {
                                result = "Persons: \(message)"
                            } else {
                                result = "Failed: \(message)"
                            }
                        }
                    }
                }
                .padding(.vertical, 5)

                Button("Fetch Devices") {
                    AddSystemController.fetchDevices(url: url, port: port, username: username, password: password, person: person) { success, message in
                        DispatchQueue.main.async {
                            if success {
                                result = "Devices: \(message)"
                            } else {
                                result = "Failed: \(message)"
                            }
                        }
                    }
                }
                .padding(.vertical, 5)

                Button("Create User") {
                    AddSystemController.createUser(url: url, port: port, username: username, password: password, person: person) { success in
                        DispatchQueue.main.async {
                            if success {
                                result = "User created successfully"
                            } else {
                                result = "Failed to create user"
                            }
                        }
                    }
                }
                .padding(.vertical, 5)

                Button("Create Device") {
                    AddSystemController.createDevice(url: url, port: port, username: username, password: password, person: person, device: device) { success in
                        DispatchQueue.main.async {
                            if success {
                                result = "Device created successfully"
                            } else {
                                result = "Failed to create device"
                            }
                        }
                    }
                }
                .padding(.vertical, 5)

                Text(result)
                    .padding()
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
    }
}
