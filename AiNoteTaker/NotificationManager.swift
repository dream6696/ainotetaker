import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // Permission চাওয়া
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("Notification permission error:", error)
            } else {
                print("Notification permission granted:", granted)
            }
        }
    }

    // নির্দিষ্ট সময়ে notification schedule করা
    func scheduleNotification(for note: Note) {
        let content = UNMutableNotificationContent()
        content.title = note.title
        content.body = note.description.isEmpty ? "Reminder" : note.description
        content.sound = .default

        // reminderDate থেকে components বের করছি
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: note.reminderDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: note.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification:", error)
            } else {
                print("Notification scheduled for:", note.reminderDate)
            }
        }
    }

    // Note delete হলে notification cancel করা
    func cancelNotification(for note: Note) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [note.id.uuidString])
        print("Notification cancelled for:", note.title)
    }
}
