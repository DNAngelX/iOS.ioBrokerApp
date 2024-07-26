import SwiftUI

struct NotificationsHistoryView: View {
    @ObservedObject var storage = NotificationStorage()

    var body: some View {
        NavigationView {
            List {
                ForEach(storage.notifications) { notification in
                    NavigationLink(destination: NotificationDetailView(notification: notification)) {
                        VStack(alignment: .leading) {
                            Text(notification.title)
                                .font(.headline)
                            Text(notification.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(notification.body)
                                .font(.body)
                                .lineLimit(1)
                                .foregroundColor(notification.isRead ? .gray : .black)
                        }
                    }
                    .contextMenu {
                        Button(action: {
                            storage.deleteNotification(notification)
                        }) {
                            Text("Delete")
                            Image(systemName: "trash")
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Notifications History")
            .navigationBarItems(trailing: Button("Clear All") {
                storage.deleteAllNotifications()
            })
        }
    }

    private func delete(at offsets: IndexSet) {
        offsets.forEach { index in
            let notification = storage.notifications[index]
            storage.deleteNotification(notification)
        }
    }
}

