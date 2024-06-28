import SwiftUI

struct SystemeView: View {
    @State private var systems: [IoBrokerSettings] = SettingsManager.shared.loadSettings()
    @State private var showAddSystemView = false

    var body: some View {
        NavigationView {
            List {
                ForEach(systems, id: \.id) { system in
                    NavigationLink(destination: SystemDetailView(system: system, systems: $systems)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(system.name)
                                    .font(.headline)
                                Text(system.url)
                                    .font(.subheadline)
                            }
                            Spacer()
                            HStack {
                                Image(systemName: system.onlineState ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                                    .foregroundColor(system.onlineState ? .blue : .gray)
                                Circle()
                                    .fill(system.isActive ? Color.green : Color.red)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteSystem)
            }
            .navigationTitle("Systeme")
            .navigationBarItems(trailing: Button(action: {
                showAddSystemView = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showAddSystemView) {
                AddSystemView(systems: $systems)
            }
        }
    }

    func deleteSystem(at offsets: IndexSet) {
        offsets.forEach { index in
            let system = systems[index]
            SettingsManager.shared.deleteSettings(system)
            systems.remove(at: index)
        }
    }
}

struct SystemDetailView: View {
    var system: IoBrokerSettings
    @Binding var systems: [IoBrokerSettings]
    @State private var isActive: Bool
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
                Text("Person: \(system.person)")
                Text("Device: \(system.device)")
                Toggle("Active", isOn: $isActive)
                    .onChange(of: isActive) { value in
                        updateSystem()
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
}
