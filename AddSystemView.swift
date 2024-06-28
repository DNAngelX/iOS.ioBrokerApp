import SwiftUI
import Alamofire

struct AddSystemView: View {
    @Binding var systems: [IoBrokerSettings]
    
    @State private var name: String = ""
    @State private var url: String = ""
    @State private var port: String = "9191"
    @State private var useCredentials: Bool = false
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var person: String = ""
    @State private var newPerson: String = ""
    @State private var device: String = UIDevice.current.model.replacingOccurrences(of: " ", with: "_")
    @State private var newDevice: String = ""
    @State private var isActive: Bool = true
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var credentialsVerified: Bool = false
    @State private var initialCheckDone: Bool = false
    @State private var existingPersons: [String] = []
    @State private var existingDevices: [String] = []

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Connection Settings")) {
                    TextField("Name", text: $name)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("URL", text: $url)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                    
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Toggle("Use Credentials", isOn: $useCredentials)
                    
                    if useCredentials {
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textContentType(.username)
                        
                        SecureField("Password", text: $password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textContentType(.password)
                    }
                    
                    Toggle("Active", isOn: $isActive)
                }
                if credentialsVerified {
                    Section(header: Text("Person")) {
                        Picker("Select person", selection: $person) {
                            Text("Enter new person").tag("")
                            ForEach(existingPersons, id: \.self) { person in
                                Text(person).tag(person)
                            }
                        }
                        .onChange(of: person) { newValue in
                            if newValue.isEmpty {
                                newPerson = ""
                            } else {
                                fetchExistingDevices(for: newValue)
                            }
                        }

                        if person.isEmpty {
                            TextField("Enter new person", text: $newPerson)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: newPerson) { value in
                                    newPerson = sanitizeInput(value)
                                }
                        }
                    }
                    if !person.isEmpty || !newPerson.isEmpty {
                        Section(header: Text("Device")) {
                            Picker("Select device", selection: $device) {
                                Text("Enter new device").tag("")
                                ForEach(existingDevices, id: \.self) { device in
                                    Text(device).tag(device)
                                }
                            }
                            .onChange(of: device) { newValue in
                                if newValue.isEmpty {
                                    newDevice = ""
                                } else {
                                    newDevice = newValue
                                }
                            }

                            if device.isEmpty {
                                TextField("Enter new device", text: $newDevice)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onChange(of: newDevice) { value in
                                        newDevice = sanitizeInput(value)
                                    }
                            }
                        }
                    }
                }
                Button("Save and Connect") {
                    if initialCheckDone {
                        saveAndConnect()
                    } else {
                        checkCredentials()
                    }
                }
                .disabled(url.isEmpty || port.isEmpty || (useCredentials && (username.isEmpty || password.isEmpty)))
            }
            .padding()
            .navigationTitle("Add System")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Connection Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    func saveSettingsWithLocation(_ location: String) {
        let settings = IoBrokerSettings(
            id: UUID(),
            name: name,
            url: url,
            port: port,
            useCredentials: useCredentials,
            username: username,
            password: password,
            person: "",
            device: "",
            location: location,
            isActive: isActive,
            onlineState: true
        )
        systems.append(settings)
        SettingsManager.shared.saveSettings(settings)
        LocationManager.shared.addZonesToSystem(settings)
        print("Saved Settings: \(settings)")
    }

    func checkCredentials() {
        IoBrokerAPI.checkOnlineStateWithoutSetting(url: url, port: port, useCredentials: useCredentials, username: username, password: password) { online, location in
            print("Check online state response: online=\(online), location=\(location)")
            if online {
                credentialsVerified = true
                initialCheckDone = true
                saveSettingsWithLocation(location)
                fetchExistingPersons()
            } else {
                credentialsVerified = false
                alertMessage = "Sorry, there is something wrong in your connection."
                showAlert = true
            }
        }
    }

    func fetchExistingPersons() {
        IoBrokerAPI.fetchPersons(url: url, port: port, useCredentials: useCredentials, username: username, password: password) { persons in
            self.existingPersons = persons
            if let firstPerson = self.existingPersons.first {
                self.person = firstPerson
                self.fetchExistingDevices(for: firstPerson)
            }
        }
    }

    func fetchExistingDevices(for person: String) {
        IoBrokerAPI.fetchDevices(for: person, url: url, port: port, useCredentials: useCredentials, username: username, password: password) { devices in
            self.existingDevices = devices
            self.device = UIDevice.current.model.replacingOccurrences(of: " ", with: "_")
        }
    }

    func saveAndConnect() {
        let personName = newPerson.isEmpty ? person : newPerson
        let deviceName = device.isEmpty ? newDevice : device

        if var lastSettings = systems.last {
            lastSettings.person = personName
            lastSettings.device = deviceName
            systems[systems.count - 1] = lastSettings
        }

        let saveSettings = {
            if var lastSettings = systems.last {
                lastSettings.person = personName
                lastSettings.device = deviceName
                systems[systems.count - 1] = lastSettings
                SettingsManager.shared.saveSettings(lastSettings)
                print("Final saved settings: \(lastSettings)")
            }
        }

        if !existingPersons.contains(personName) {
            IoBrokerAPI.createUser(person: personName, id: systems.last!.id) { success in
                if success {
                    self.setupDevice(for: personName) {
                        saveSettings()
                    }
                } else {
                    self.alertMessage = "Failed to create person."
                    self.showAlert = true
                }
            }
        } else {
            setupDevice(for: personName) {
                saveSettings()
            }
        }
    }

    func setupDevice(for person: String, completion: @escaping () -> Void) {
        let deviceName = device.isEmpty ? newDevice : device
        if !existingDevices.contains(deviceName) {
            IoBrokerAPI.createDevice(person: person, device: deviceName, id: systems.last!.id) { success in
                if success {
                    self.presentationMode.wrappedValue.dismiss()
                    completion()
                } else {
                    self.alertMessage = "Failed to create device."
                    self.showAlert = true
                }
            }
        } else {
            self.presentationMode.wrappedValue.dismiss()
            completion()
        }
    }

    func sanitizeInput(_ input: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics
        return input.filter { allowedCharacters.contains($0.unicodeScalars.first!) }
            .replacingOccurrences(of: " ", with: "_")
    }
}
