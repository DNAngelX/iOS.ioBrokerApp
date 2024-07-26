import UserNotifications
import UIKit

class NotificationController {
    static let shared = NotificationController()
    let notificationStorage = NotificationStorage()

    func handleNotification(_ json: [String: Any]) {
        guard let payload = json["payload"] as? [String: Any] else {
            return
        }

        guard let aps = payload["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let title = alert["title"] as? String else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.sound = .default

        var body = ""
        var bodyHtml: String? = nil
        
        if let alertBody = alert["body"] as? String {
            body = alertBody
            content.body = body
        }
        
        if let htmlBody = payload["body-html"] as? String {
            bodyHtml = htmlBody
        }

        if let subtitle = alert["subtitle"] as? String {
            content.subtitle = subtitle
        }

        if let category = aps["category"] as? String {
            content.categoryIdentifier = category
        }

        if let sound = aps["sound"] as? String {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
        }

        let group = DispatchGroup()

        if let imageUrlString = payload["image-url"] as? String, let imageUrl = URL(string: imageUrlString) {
            group.enter()
            loadAttachment(from: imageUrl, identifier: "image") { attachment in
                if let attachment = attachment {
                    content.attachments.append(attachment)
                }
                group.leave()
            }
        }

        if let videoUrlString = payload["video-url"] as? String, let videoUrl = URL(string: videoUrlString) {
            group.enter()
            loadAttachment(from: videoUrl, identifier: "video") { attachment in
                if let attachment = attachment {
                    content.attachments.append(attachment)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if error == nil {
                    let notification = NotificationModel(
                        title: title,
                        subtitle: content.subtitle,
                        body: body,
                        bodyHtml: bodyHtml,
                        date: Date(),
                        isRead: false,
                        imageUrl: payload["image-url"] as? String,
                        videoUrl: payload["video-url"] as? String
                    )
                    self.notificationStorage.addNotification(notification)
                    NotificationCenter.default.post(name: NSNotification.Name("OpenNotification"), object: notification)

                    // Send acknowledgment for the notification
                    if let webSocketId = IoBrokerAPI.webSocketMap.first(where: { $0.value == notification.id })?.key {
                        IoBrokerAPI.sendNotificationAcknowledgment(json, for: webSocketId)
                    }
                }
            }
        }
    }

    private func loadAttachment(from url: URL, identifier: String, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { location, response, error in
            guard let location = location else {
                completion(nil)
                return
            }
            let directory = FileManager.default.temporaryDirectory
            let uniqueURL = directory.appendingPathComponent(UUID().uuidString + "." + url.pathExtension)
            try? FileManager.default.moveItem(at: location, to: uniqueURL)

            do {
                let attachment = try UNNotificationAttachment(identifier: identifier, url: uniqueURL, options: nil)
                completion(attachment)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
}
