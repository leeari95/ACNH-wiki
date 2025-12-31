//
//  NotificationManager.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2026/01/01.
//

import UserNotifications

final class NotificationManager {

    enum Mode {
        case on
        case off
    }

    static let shared = NotificationManager()
    private(set) var mode: Mode
    private let notificationCenter = UNUserNotificationCenter.current()

    private static let userDefaultsKey = "notificationState"

    private init() {
        if let state = UserDefaults.standard.object(forKey: Self.userDefaultsKey) as? Bool {
            self.mode = state ? .on : .off
        } else {
            self.mode = .off
            UserDefaults.standard.set(false, forKey: Self.userDefaultsKey)
        }
    }

    // MARK: - Permission

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    debugPrint("Notification authorization error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                completion(granted)
            }
        }
    }

    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - Toggle

    func toggle() {
        mode = mode == .on ? .off : .on
        UserDefaults.standard.set(mode == .on, forKey: Self.userDefaultsKey)

        if mode == .off {
            removeAllScheduledNotifications()
        }
    }

    func setMode(_ newMode: Mode) {
        mode = newMode
        UserDefaults.standard.set(mode == .on, forKey: Self.userDefaultsKey)

        if mode == .off {
            removeAllScheduledNotifications()
        }
    }

    // MARK: - Scheduling

    func scheduleRareCreatureNotification(
        creatureName: String,
        appearanceTime: DateComponents,
        identifier: String
    ) {
        guard mode == .on else { return }

        let content = UNMutableNotificationContent()
        content.title = "Rare creature alert".localized
        content.body = String(format: "Rare creature appearing".localized, creatureName)
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: appearanceTime,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                debugPrint("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    func scheduleNotification(
        title: String,
        body: String,
        dateComponents: DateComponents,
        identifier: String,
        repeats: Bool = false
    ) {
        guard mode == .on else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: repeats
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                debugPrint("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    func scheduleNotificationAfterInterval(
        title: String,
        body: String,
        timeInterval: TimeInterval,
        identifier: String
    ) {
        guard mode == .on else { return }
        guard timeInterval > 0 else {
            debugPrint("Invalid timeInterval: \(timeInterval). Must be greater than 0.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                debugPrint("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Management

    func removeScheduledNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func removeScheduledNotifications(identifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removeAllScheduledNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
}
