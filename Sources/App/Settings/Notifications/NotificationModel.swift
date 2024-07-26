import Foundation

struct NotificationModel: Identifiable, Codable {
    var id = UUID()
    var title: String
    var subtitle: String
    var body: String
    var bodyHtml: String?
    var date: Date = Date()
    var isRead: Bool = false
    var imageUrl: String?
    var videoUrl: String?
    var mediaUrl: String?

    static func == (lhs: NotificationModel, rhs: NotificationModel) -> Bool {
        return lhs.id == rhs.id
    }
}

class NotificationStorage: ObservableObject {
    @Published var notifications: [NotificationModel] = [] {
        didSet {
            saveNotifications()
        }
    }

    init() {
        loadNotifications()
    }

    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: "notifications")
        }
    }

    private func loadNotifications() {
        if let savedNotifications = UserDefaults.standard.data(forKey: "notifications"),
           let decodedNotifications = try? JSONDecoder().decode([NotificationModel].self, from: savedNotifications) {
            notifications = decodedNotifications.sorted(by: { $0.date > $1.date })
        }
    }

    func addNotification(_ notification: NotificationModel) {
        notifications.insert(notification, at: 0)
        if notifications.count > 50 {
            notifications.removeLast()
        }
    }

    func markAsRead(_ notification: NotificationModel) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }

    func deleteNotification(_ notification: NotificationModel) {
        notifications.removeAll { $0.id == notification.id }
    }

    func deleteAllNotifications() {
        notifications.removeAll()
    }
}
