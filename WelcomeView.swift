import SwiftUI
import Alamofire

struct WelcomeView: View {
    var person: String
    @State private var device: String
    var url: String
    var port: String

    @State private var isConnected: Bool = true

    // Explicitly define the initializer
    init(person: String, device: String, url: String, port: String) {
        self.person = person
        _device = State(initialValue: device)
        self.url = url
        self.port = port
    }

    var body: some View {
        VStack {
            Text("Welcome \(person)!")
                .font(.largeTitle)
                .padding()

            Text("Device: \(device)")
                .font(.headline)
                .padding()

            Text("Status: \(isConnected ? "Connected" : "Disconnected")")
                .foregroundColor(isConnected ? .green : .red)
                .padding()
        }
        .onAppear {
            checkConnectionStatus()
            Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
                checkConnectionStatus()
            }
        }
        /*.navigationBarItems(trailing: NavigationLink(destination: SettingsView(person: person, device: $device, url: url, port: port)) {
            Text("Settings")
        })
         */
    }

    func checkConnectionStatus() {
        
    }

}
