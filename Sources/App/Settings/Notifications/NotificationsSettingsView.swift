import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @State private var notificationsEnabled = false
    @State private var selectedTone = "Default"
    @State private var badgeNumber = UIApplication.shared.applicationIconBadgeNumber
    @State private var resetBadgeAutomatically = false
    @State private var sounds: [String] = ["Imported", "System"]
    @State private var selectedSound: String = "System"

    var body: some View {
        Form {
            Section(header: Text("Push Notifications")) {
                HStack {
                   Text("Push Notifications aktiviert")
                   Spacer()
                   Text(notificationsEnabled ? "Ja" : "Nein")
                       .foregroundColor(notificationsEnabled ? .green : .red)
               }
               NavigationLink(destination: NotificationsHistoryView()) {
                   Text("Notification History")
               }
            }

            Section(header: Text("Töne")) {
                NavigationLink(destination: toneSelectionView) {
                    HStack {
                        Text("Töne")
                        Spacer()
                        Text(selectedTone)
                            .foregroundColor(.gray)
                    }
                }
            }

            Section(header: Text("Badge")) {
                Button("Badge zurücksetzen") {
                    resetBadge()
                }
                HStack {
                    Text("Aktuelle Badge Nummer")
                    Spacer()
                    Text("\(badgeNumber)")
                        .foregroundColor(.gray)
                }
                Toggle("Automatisch", isOn: $resetBadgeAutomatically)
                Text("Setzt den Badge bei jedem Start der App auf 0 zurück")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Notifications Einstellungen")
        .onAppear {
            checkNotificationsEnabled()
            badgeNumber = UIApplication.shared.applicationIconBadgeNumber
        }
        .onChange(of: resetBadgeAutomatically) { newValue in
            if newValue {
                UIApplication.shared.applicationIconBadgeNumber = 0
                badgeNumber = 0
            }
        }
    }

    private func checkNotificationsEnabled() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func resetBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        badgeNumber = 0
    }

    private var toneSelectionView: some View {
        VStack {
            List(sounds, id: \.self) { sound in
                Button(action: {
                    selectedTone = sound
                }) {
                    HStack {
                        Text(sound)
                        if sound == selectedTone {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Töne Auswahl")
        }
    }
}
