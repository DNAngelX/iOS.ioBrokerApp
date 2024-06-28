import SwiftUI
import MapKit
import CoreLocation

struct LocationSettingsView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @State private var address: String = ""
    @State private var coordinate: CLLocationCoordinate2D? = nil
    @State private var zoneName: String = ""
    @State private var radius: String = ""
    @State private var isActive: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showAddZonePopup = false
    @State private var selectedZone: Zone? = nil

    var body: some View {
        Form {
            Section(header: Text("Standortquellen")) {
                Toggle("Zone betreten / verlassen", isOn: $locationManager.enterExitToggle)
                Toggle("Hintergrundaktualisierung", isOn: $locationManager.backgroundUpdateToggle)
                Toggle("Erhebliche Standortänderung", isOn: $locationManager.significantChangeToggle)
            }

            Section(header: Text("Zonen")) {
                ForEach(locationManager.zones) { zone in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(zone.name)
                            Text(zone.isActive ? "Aktiv" : "Inaktiv")
                                .foregroundColor(zone.isActive ? .green : .red)
                            if let distance = zone.distance {
                                Text(String(format: "Entfernung: %.2f m", distance))
                                    .foregroundColor(.blue)
                            }
                        }
                        Spacer()
                        Button(action: {
                            selectedZone = zone
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
                Button("Zone hinzufügen") {
                    showAddZonePopup = true
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Fehler"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showAddZonePopup) {
            addZoneView
        }
        .sheet(item: $selectedZone) { zone in
            zoneDetailView(zone: zone)
        }
    }

    private var addZoneView: some View {
        VStack {
            Text("Neue Zone hinzufügen").font(.headline).padding()
            Form {
                CustomTextField(placeholder: "Name der Zone", text: $zoneName)
                CustomNumberField(placeholder: "Radius der Zone (m)", text: $radius)
                Toggle("Aktivieren", isOn: $isActive)
                TextField("Adresse", text: $address)
                Button("Koordinaten abrufen") {
                    getCoordinates(forAddress: address)
                }
                if let coordinate = coordinate {
                    Text("Koordinaten: \(coordinate.latitude), \(coordinate.longitude)")
                }
                Button("Zone speichern") {
                    saveZone()
                }
            }
            .padding()
        }
    }

    private func zoneDetailView(zone: Zone) -> some View {
        VStack {
            Text("Zone Details").font(.headline).padding()
            Form {
                HStack {
                    Text("Name der Zone:")
                    Spacer()
                    Text(zone.name)
                }
                HStack {
                    Text("Radius:")
                    Spacer()
                    Text("\(zone.radius, specifier: "%.2f") m")
                }
                HStack {
                    Text("Koordinaten:")
                    Spacer()
                    Text("\(zone.latitude), \(zone.longitude)")
                }
                if let distance = zone.distance {
                    HStack {
                        Text("Entfernung:")
                        Spacer()
                        Text(String(format: "%.2f m", distance))
                    }
                }
                Toggle("Aktivieren", isOn: Binding<Bool>(
                    get: { zone.isActive },
                    set: { isActive in
                        if let index = locationManager.zones.firstIndex(where: { $0.id == zone.id }) {
                            locationManager.zones[index].isActive = isActive
                        }
                    }
                ))
                Button("Zone löschen") {
                    deleteZone(zone: zone)
                    selectedZone = nil
                }
            }
            .padding()
        }
    }

    private func deleteZone(zone: Zone) {
        if let index = locationManager.zones.firstIndex(where: { $0.id == zone.id }) {
            locationManager.zones.remove(at: index)
        }
    }

    private func saveZone() {
        guard !zoneName.isEmpty, let coordinate = coordinate, let radiusValue = Double(radius) else {
            alertMessage = "Bitte geben Sie einen gültigen Namen, Radius und Adresse ein."
            showAlert = true
            return
        }

        let newZone = Zone(name: zoneName, latitude: coordinate.latitude, longitude: coordinate.longitude, radius: radiusValue, isActive: isActive)
        locationManager.zones.append(newZone)
        for system in SettingsManager.shared.loadSettings() {
            if system.isActive {
                IoBrokerAPI.setPresence(id: system.id, locationName: newZone.name, person: system.person, presence: false) { success in
                    if !success {
                        print("Failed to add zone to system \(system.name)")
                    }
                }
            }
        }
        zoneName = ""
        radius = ""
        isActive = false
        address = ""
        self.coordinate = nil
        showAddZonePopup = false // Close the popup after saving
    }

    private func getCoordinates(forAddress address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                alertMessage = "Fehler beim Abrufen der Koordinaten: \(error.localizedDescription)"
                showAlert = true
                return
            }
            if let placemark = placemarks?.first, let location = placemark.location {
                self.coordinate = location.coordinate
            } else {
                alertMessage = "Keine Koordinaten gefunden"
                showAlert = true
            }
        }
    }
}

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .onChange(of: text) { newValue in
                let filtered = newValue
                    .filter { $0.isLetter || $0.isNumber }
                    .replacingOccurrences(of: "ä", with: "ae")
                    .replacingOccurrences(of: "ö", with: "oe")
                    .replacingOccurrences(of: "ü", with: "ue")
                    .replacingOccurrences(of: "ß", with: "ss")
                let replaced = filtered.replacingOccurrences(of: " ", with: "_")
                if replaced != newValue {
                    text = replaced
                }
            }
    }
}

struct CustomNumberField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .onChange(of: text) { newValue in
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    text = filtered
                }
            }
    }
}
