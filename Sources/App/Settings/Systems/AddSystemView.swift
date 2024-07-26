import SwiftUI
import MapKit

struct AddSystemView: View {
    @Binding var systems: [IoBrokerSettings]
    @State private var name: String = ""
    @State private var url: String = ""
    @State private var port: String = "9192"
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var person: String = ""
    @State private var newPerson: String = ""
    @State private var device: String = UIDevice.current.model.replacingOccurrences(of: " ", with: "_")
    @State private var newDevice: String = ""
    @State private var existingPersons: [String] = []
    @State private var existingDevices: [String] = []
    @State private var location: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var currentPage = 0
    @State private var isActive: Bool = true

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                if currentPage == 0 {
                    Page1(name: $name, url: $url, port: $port, currentPage: $currentPage, showAlert: $showAlert, alertMessage: $alertMessage)
                } else if currentPage == 1 {
                    Page2(url: $url, port: $port, username: $username, password: $password, currentPage: $currentPage, location: $location, showAlert: $showAlert, alertMessage: $alertMessage)
                } else if currentPage == 2 {
                    Page3(person: $person, newPerson: $newPerson, existingPersons: $existingPersons, url: $url, port: $port, username: $username, password: $password, currentPage: $currentPage)
                } else if currentPage == 3 {
                    Page4(device: $device, newDevice: $newDevice, existingDevices: $existingDevices, person: $person, newPerson: $newPerson, url: $url, port: $port, username: $username, password: $password, currentPage: $currentPage)
                } else if currentPage == 4 {
                    Page5(name: $name, url: $url, port: $port, websocketPort: $port, username: $username, password: $password, person: $person, newPerson: $newPerson, device: $device, newDevice: $newDevice, location: $location, isActive: $isActive, systems: $systems, currentPage: $currentPage, presentationMode: _presentationMode)
                }
            }
            .navigationBarTitle("Add System", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

struct Page1: View {
    @Binding var name: String
    @Binding var url: String
    @Binding var port: String
    @Binding var currentPage: Int
    @Binding var showAlert: Bool
    @Binding var alertMessage: String

    var body: some View {
        VStack {
            Form {
                Section(header: Text("WebSocket Settings")) {
                    TextField("Name", text: $name)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                    TextField("URL", text: $url)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                    Text("Enter the IP address or the public address of the WebSocket, including the port specified in the IoBroker adapter.")
                        .padding()
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Button("Check WebSocket Connection") {
                AddSystemController.connectWebSocketCheck(urlString: url, port: port) { success in
                    if success {
                        currentPage = 1
                    } else {
                        showAlert = true
                        alertMessage = "WebSocket not reachable"
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

struct Page2: View {
    @Binding var url: String
    @Binding var port: String
    @Binding var username: String
    @Binding var password: String
    @Binding var currentPage: Int
    @Binding var location: String
    @Binding var showAlert: Bool
    @Binding var alertMessage: String

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Credentials")) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.username)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                    SecureField("Password", text: $password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
            }
            .padding()

            Button("Check Credentials") {
                AddSystemController.checkWebSocketCredentials(url: url, port: port, username: username, password: password) { success, response in
                    if success {
                        location = response
                        currentPage = 2
                    } else {
                        showAlert = true
                        alertMessage = response
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

struct Page3: View {
    @Binding var person: String
    @Binding var newPerson: String
    @Binding var existingPersons: [String]
    @Binding var url: String
    @Binding var port: String
    @Binding var username: String
    @Binding var password: String
    @Binding var currentPage: Int
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        VStack {
            Form {
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
            }
            .padding()

            Button("Next") {
                if person.isEmpty {
                    AddSystemController.createUser(url: url, port: port, username: username, password: password, person: newPerson) { success in
                        if success {
                            currentPage = 3
                        } else {
                            showAlert = true
                            alertMessage = "Failed to create person."
                        }
                    }
                } else {
                    currentPage = 3
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .onAppear {
            AddSystemController.fetchPersons(url: url, port: port, username: username, password: password) { success, response in
                if success {
                    existingPersons = response.split(separator: ",").map { String($0) }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .padding()
    }
}

struct Page4: View {
    @Binding var device: String
    @Binding var newDevice: String
    @Binding var existingDevices: [String]
    @Binding var person: String
    @Binding var newPerson: String
    @Binding var url: String
    @Binding var port: String
    @Binding var username: String
    @Binding var password: String
    @Binding var currentPage: Int
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        VStack {
            Form {
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
            .padding()

            Button("Next") {
                let selectedPerson = person.isEmpty ? newPerson : person
                AddSystemController.createDevice(url: url, port: port, username: username, password: password, person: selectedPerson, device: newDevice.isEmpty ? device : newDevice) { success in
                    if success {
                        currentPage = 4
                    } else {
                        showAlert = true
                        alertMessage = "Failed to create device."
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .onAppear {
            let selectedPerson = person.isEmpty ? newPerson : person
            AddSystemController.fetchDevices(url: url, port: port, username: username, password: password, person: selectedPerson) { success, response in
                if success {
                    existingDevices = response.split(separator: ",").map { String($0) }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .padding()
    }
}

struct Page5: View {
    @Binding var name: String
    @Binding var url: String
    @Binding var port: String
    @Binding var websocketPort: String
    @Binding var username: String
    @Binding var password: String
    @Binding var person: String
    @Binding var newPerson: String
    @Binding var device: String
    @Binding var newDevice: String
    @Binding var location: String
    @Binding var isActive: Bool
    @Binding var systems: [IoBrokerSettings]
    @Binding var currentPage: Int
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Summary").font(.headline).foregroundColor(.blue)) {
                Text("Name: \(name)")
                Text("URL: \(url)")
                Text("Port: \(port)")
                Text("Username: \(username)")
                Text("Location: \(location)")
                MapView(coordinate: getLocationCoordinate(from: location))
                    .frame(height: 200)
            }
            Button("Save and Connect") {
                saveSettingsWithLocation(location)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    func saveSettingsWithLocation(_ location: String) {
        let sanitizedPerson = sanitizeInput(person.isEmpty ? newPerson : person)
        let sanitizedDevice = sanitizeInput(device.isEmpty ? newDevice : device)

        let settings = IoBrokerSettings(
            id: UUID(),
            name: name,
            url: url,
            port: port,
            websocketPort: websocketPort,
            useCredentials: true,
            username: username,
            password: password,
            person: sanitizedPerson,
            device: sanitizedDevice,
            location: location,
            isActive: isActive,
            onlineState: true
        )
        systems.append(settings)
        SettingsManager.shared.saveSettings(settings)
        LocationManager.shared.addZonesToSystem(settings)
        print("Saved Settings: \(settings)")
        
        // Disconnect the WebSocket
        AddSystemController.disconnectWebSocketCheck()
        
        // Trigger manual WebSocket check
        IoBrokerAPI.checkAllWebSocketConnections()
        
        // Close the view
        DispatchQueue.main.async {
            presentationMode.wrappedValue.dismiss()
        }
    }

    func getLocationCoordinate(from location: String) -> CLLocationCoordinate2D {
        let components = location.split(separator: ",")
        if components.count == 2, let latitude = Double(components[0]), let longitude = Double(components[1]) {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        return CLLocationCoordinate2D()
    }

    func sanitizeInput(_ input: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        return input.filter { allowedCharacters.contains($0.unicodeScalars.first!) }
            .replacingOccurrences(of: " ", with: "_")
    }
}

func sanitizeInput(_ input: String) -> String {
    let allowedCharacters = CharacterSet.alphanumerics
    return input.filter { allowedCharacters.contains($0.unicodeScalars.first!) }
        .replacingOccurrences(of: " ", with: "_")
}


struct AddSystemView_Previews: PreviewProvider {
    @State static var systems: [IoBrokerSettings] = []

    static var previews: some View {
        AddSystemView(systems: $systems)
    }
}
