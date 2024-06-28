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
                NavigationLink(destination: GroundSettingsView()) {
                    Text("Allgemein")
                }
                NavigationLink(destination: LocationSettingsView()) {
                    Text("Standort")
                }
                NavigationLink(destination: MessagesSettingsView()) {
                    Text("Benachrichtigungen")
                }
            }

            Section(header: Text("Weitere Einstellungen")) {
                NavigationLink(destination: ActionsSettingsView()) {
                    Text("Aktionen")
                }
                NavigationLink(destination: SensorsSettingsView()) {
                    Text("Sensoren")
                }
                NavigationLink(destination: AppleWatchSettingsView()) {
                    Text("Apple Watch")
                }
                NavigationLink(destination: NFCTagsSettingsView()) {
                    Text("NFC Tags")
                }
                NavigationLink(destination: WidgetsSettingsView()) {
                    Text("Widgets")
                }
            }

            Section(header: Text("Support")) {
                NavigationLink(destination: HelpSettingsView()) {
                    Text("Hilfe")
                }
                NavigationLink(destination: PrivacySettingsView()) {
                    Text("Privatsphäre")
                }
            }

            Section {
                Button("Logout") {
                    logout()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Settings")
        .navigationBarItems(trailing: Button("Done") {
            presentationMode.wrappedValue.dismiss()
        })
    }

    func logout() {
        SensorManager.shared.resetSensors()
        SettingsManager.shared.clearSettings()
        presentationMode.wrappedValue.dismiss()
        // Redirect to ContentView
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = UIHostingController(rootView: StartView())
            window.makeKeyAndVisible()
        }
    }
}

// Placeholder views for the different settings screens
struct GroundSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("Dummy Menüpunkt")
            }
        }
        .navigationTitle("Allgemein")
    }
}


struct MessagesSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("Dummy Eintrag")
            }
        }
        .navigationTitle("Benachrichtigungen")
    }
}

struct ActionsSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("Dummy Eintrag")
            }
        }
        .navigationTitle("Aktionen")
    }
}

struct AppleWatchSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("Dummy Eintrag")
            }
        }
        .navigationTitle("Apple Watch")
    }
}

struct NFCTagsSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("Dummy Eintrag")
            }
        }
        .navigationTitle("NFC Tags")
    }
}

struct WidgetsSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("Dummy Eintrag")
            }
        }
        .navigationTitle("Widgets")
    }
}

struct HelpSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("Dummy Eintrag")
            }
        }
        .navigationTitle("Hilfe")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("Dummy Eintrag")
            }
        }
        .navigationTitle("Privatsphäre")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
