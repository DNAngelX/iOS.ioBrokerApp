import SwiftUI

@main
struct IoBrokerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var notificationStorage = NotificationStorage()
    @State private var notificationToOpen: NotificationModel?

    var body: some Scene {
        WindowGroup {
            NavigationView {
                StartView()
                    .environmentObject(notificationStorage)
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenNotification"))) { notification in
                        if let notification = notification.object as? NotificationModel {
                            self.notificationToOpen = notification
                            notificationStorage.addNotification(notification)
                        }
                    }
                    .sheet(item: $notificationToOpen) { notification in
                        NotificationDetailView(notification: notification)
                    }
            }
        }
    }
}
