//
//  InactivityNotificationService.swift
//  GymTracker
//
//  Schedules a single local notification that fires after `inactivityDays` of not opening
//  the app. Each app launch cancels and re-schedules, so the notification only ever fires
//  if the user actually goes silent for the full period.
//

import Foundation
import UserNotifications

enum InactivityNotificationService {

    private static let identifier = "inactivity_reminder_v1"
    private static let inactivityDays = 7

    /// Request notification permission silently. Safe to call repeatedly.
    /// If the user already granted (e.g. via RestTimer), this is a no-op.
    static func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
            default:
                break
            }
        }
    }

    /// Cancels any pending inactivity reminder and schedules a fresh one `inactivityDays` from now.
    /// Call on every app foreground — that's exactly how we ensure it only fires when the user
    /// actually doesn't open the app for the full window.
    static func rescheduleOnAppOpen() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Don't schedule if user denied notifications; respect their choice.
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = String(localized: "Время тренироваться")
            content.body = String(localized: "Прошла неделя без тренировки. Возвращайся и продолжи прогресс.")
            content.sound = .default

            let interval = TimeInterval(inactivityDays * 24 * 60 * 60)
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: interval,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            center.add(request, withCompletionHandler: nil)
        }
    }

    /// Removes the pending reminder without rescheduling.
    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
