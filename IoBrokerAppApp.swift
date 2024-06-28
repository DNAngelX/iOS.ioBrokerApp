import SwiftUI


@main
struct IoBrokerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            StartView()
        }
    }
}
