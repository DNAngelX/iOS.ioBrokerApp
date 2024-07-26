import UIKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    var notificationToOpen: NotificationModel?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("Application did finish launching")
        registerForPushNotifications()
        
        // Initialize WebSocket connection for each active system
        IoBrokerAPI.checkAllWebSocketConnections()
        
        // Schedule periodic checks
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            IoBrokerAPI.checkAllWebSocketConnections()
        }
        return true
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self.getNotificationSettings()
        }
    }

    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        SensorManager.shared.sensorValues["deviceToken"] = token
        SensorManager.shared.updateSensorValues()

        // Send device token to server
        IoBrokerAPI.checkAllWebSocketConnections()
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }

    // UNUserNotificationCenterDelegate methods
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let aps = userInfo["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: Any],
           let title = alert["title"] as? String,
           let body = alert["body"] as? String {
            
            let subtitle = alert["subtitle"] as? String ?? ""
            notificationToOpen = NotificationModel(title: title, subtitle: subtitle, body: body)
            NotificationCenter.default.post(name: NSNotification.Name("OpenNotification"), object: notificationToOpen)
        }
        completionHandler()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        application.beginBackgroundTask(withName: "KeepAlive") {
            // End the task if time expires.
            application.endBackgroundTask(UIBackgroundTaskIdentifier.invalid)
        }
        let systems = SettingsManager.shared.loadSettings()
        for system in systems {
            if system.isActive {
                IoBrokerAPI.checkWebSocketConnection(id: system.id)
            }
        }
    }
}
