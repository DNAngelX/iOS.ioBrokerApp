import SwiftUI

struct SensorsSettingsView: View {
    @State private var selectedInterval: Int = SensorSettings.shared.updateInterval
    @ObservedObject private var sensorManager = SensorManager.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name - Regelmäßige Aktualisierung")) {
                    HStack {
                        Text("Aktuelles Intervall")
                        Spacer()
                        Text(SensorSettings.shared.intervalLabel(for: selectedInterval))
                            .foregroundColor(.gray)
                    }
                    Text("Wenn diese Option aktiviert ist, werden diese Sensoren mit dieser Frequenz aktualisiert, während die App im Vordergrund geöffnet ist.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    Picker("Intervall", selection: $selectedInterval) {
                        ForEach(SensorSettings.shared.availableIntervals.keys.sorted(), id: \.self) { interval in
                            Text(SensorSettings.shared.intervalLabel(for: interval)).tag(interval)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedInterval) { newValue in
                        SensorSettings.shared.updateInterval = newValue
                        SensorManager.shared.updateInterval(newValue)
                    }
                }
                
                Section(header: Text("Sensoren")) {
                    ForEach($sensorManager.sensors) { $sensor in
                        NavigationLink(destination: SensorDetailView(sensor: $sensor)) {
                            HStack {
                                Image(systemName: sensor.iconName)
                                VStack(alignment: .leading) {
                                    Text(sensor.name)
                                    if let deviceClass = sensor.deviceClass {
                                        Text(deviceClass).font(.footnote).foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                                Text(sensor.value)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sensoren Einstellungen")
            .onAppear {
                selectedInterval = SensorSettings.shared.updateInterval
                sensorManager.sensors = DefaultSensors.defaultSensors
                SensorManager.shared.startMonitoringSensors()
            }
        }
    }
}

struct SensorDetailView: View {
    @Binding var sensor: IoTSensor

    var body: some View {
        Form {
            Section(header: Text(sensor.name)) {
                Toggle("Aktiviert", isOn: $sensor.isEnabled)
                    .onChange(of: sensor.isEnabled) { newValue in
                        SensorManager.shared.updateSensor(sensor)
                    }
                HStack {
                    Text("Zustand")
                    Spacer()
                    Text(sensor.value)
                        .foregroundColor(.gray)
                }
                if let deviceClass = sensor.deviceClass {
                    HStack {
                        Text("Geräteklasse")
                        Spacer()
                        Text(deviceClass)
                            .foregroundColor(.gray)
                    }
                }
                HStack {
                    Text("Symbol")
                    Spacer()
                    Image(systemName: sensor.iconName)
                }
            }
        }
        .navigationTitle(sensor.name)
    }
}
