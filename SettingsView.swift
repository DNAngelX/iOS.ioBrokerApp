import SwiftUI
import Alamofire

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Base")) {
                NavigationLink(destination: SystemeView()) {
                    Text("Systeme")
                }
                NavigationLink(destination: LocationSettingsView()) {
                    Text("Standort")
                }
                NavigationLink(destination: NotificationsSettingsView()) {
                    Text("Benachrichtigungen")
                }
            }

            Section(header: Text("Weitere Einstellungen")) {
                NavigationLink(destination: SensorsSettingsView()) {
                    Text("Sensoren")
                }
                NavigationLink(destination: NFCViewControllerWrapper()) {
                    Text("NFC Tags")
                }
            }
            
        }
        .navigationTitle("Settings")
        .navigationBarItems(trailing: Button("Done") {
            presentationMode.wrappedValue.dismiss()
        })
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
