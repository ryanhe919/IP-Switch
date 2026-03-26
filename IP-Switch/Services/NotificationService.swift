//
//  NotificationService.swift
//  IP-Switch
//
//  Created by Yufan He on 2026/3/26.
//

import Foundation
import UserNotifications

@MainActor
class NotificationService {
    static let shared = NotificationService()

    private var authorized = false

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in
                self.authorized = granted
            }
        }
    }

    func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
