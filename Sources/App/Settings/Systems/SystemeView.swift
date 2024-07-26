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
