import Foundation
import UserNotifications

enum NotificationService {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleDueDate(for item: ListItem, in documentTitle: String) async {
        guard let dueDate = item.dueDate else { return }

        let content = UNMutableNotificationContent()
        content.title = documentTitle
        content.body = item.text.isEmpty ? "Task due" : item.text
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancelNotification(for itemID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [itemID.uuidString])
    }
}
