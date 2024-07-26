import SwiftUI
import MapKit

struct SystemDetailView: View {
    var system: IoBrokerSettings
    @Binding var systems: [IoBrokerSettings]
    @State private var isActive: Bool
    @State private var existingPersons: [String] = []
    @State private var existingDevices: [String] = []
    @Environment(\.presentationMode) var presentationMode

    init(system: IoBrokerSettings, systems: Binding<[IoBrokerSettings]>) {
        self.system = system
        self._systems = systems
        self._isActive = State(initialValue: system.isActive)
    }

    var body: some View {
        Form {
            Section(header: Text("System Details")) {
                Text("Name: \(system.name)")
                Text("URL: \(system.url)")
                Text("Port: \(system.port)")
                Text("Websocket Port: \(system.websocketPort)")
                Text("Person: \(system.person)")
                Text("Device: \(system.device)")
                Toggle("Active", isOn: $isActive)
                    .onChange(of: isActive) { value in
                        if value {
                            activateSystem()
                        } else {
                            deactivateSystem()
                        }
                    }
            }
            Section {
                Button("Delete System") {
                    deleteSystem()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("System Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let index = systems.firstIndex(where: { $0.id == system.id }) {
                self.isActive = systems[index].isActive
            }
        }
    }

    func activateSystem() {
        updateSystem()
        saveAndConnect(system: system)
    }

    func deactivateSystem() {
        updateSystem()
    }

    func updateSystem() {
        if let index = systems.firstIndex(where: { $0.id == system.id }) {
            systems[index].isActive = isActive
            SettingsManager.shared.saveSettings(systems[index])
        }
    }

    func deleteSystem() {
        if let index = systems.firstIndex(where: { $0.id == system.id }) {
            SettingsManager.shared.deleteSettings(systems[index])
            systems.remove(at: index)
            presentationMode.wrappedValue.dismiss()
        }
    }

    func saveAndConnect(system: IoBrokerSettings) {
        IoBrokerAPI.checkOnlineState(url: system.url, port: system.port, username: system.username, password: system.password) { online, location in
            print("Check online state response: online=\(online), location=\(location)")
            if online {
                fetchExistingPersons(for: system)
            } else {
                print("Sorry, there is something wrong in your connection.")
            }
        }
        
        // Trigger manual WebSocket check
        IoBrokerAPI.checkAllWebSocketConnections()
    }

    func fetchExistingPersons(for system: IoBrokerSettings) {
        IoBrokerAPI.fetchPersons(url: system.url, port: system.port, username: system.username, password: system.password) { success, personsString in
            if success {
                self.existingPersons = personsString.split(separator: ",").map { String($0) }
                let personName = system.person
                let deviceName = system.device

                if !self.existingPersons.contains(personName) {
                    IoBrokerAPI.createUser(url: system.url, port: system.port, username: system.username, password: system.password, person: personName) { success in
                        if success {
                            self.setupDevice(for: personName, system: system) {
                                self.saveSettings(personName: personName, deviceName: deviceName, system: system)
                            }
                        } else {
                            print("Failed to create person.")
                        }
                    }
                } else {
                    setupDevice(for: personName, system: system) {
                        self.saveSettings(personName: personName, deviceName: deviceName, system: system)
                    }
                }
            } else {
                print("Failed to fetch persons: \(personsString)")
            }
        }
    }

    func setupDevice(for person: String, system: IoBrokerSettings, completion: @escaping () -> Void) {
        IoBrokerAPI.fetchDevices(url: system.url, port: system.port, username: system.username, password: system.password, person: person) { success, devicesString in
            if success {
                self.existingDevices = devicesString.split(separator: ",").map { String($0) }
                let deviceName = system.device
                if !self.existingDevices.contains(deviceName) {
                    IoBrokerAPI.createDevice(url: system.url, port: system.port, username: system.username, password: system.password, person: person, device: deviceName) { success in
                        if success {
                            completion()
                        } else {
                            print("Failed to create device.")
                        }
                    }
                } else {
                    completion()
                }
            } else {
                print("Failed to fetch devices: \(devicesString)")
            }
        }
    }

    func saveSettings(personName: String, deviceName: String, system: IoBrokerSettings) {
        if let index = systems.firstIndex(where: { $0.id == system.id }) {
            systems[index].person = personName
            systems[index].device = deviceName
            SettingsManager.shared.saveSettings(systems[index])
        }
    }
}
