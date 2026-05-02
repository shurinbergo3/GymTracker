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

    // Decay warnings — fire relative to last workout date, aligned with gamification phases.
    private static let decayWarningIDs = [
        "decay_warning_form_v1",   // day 3 — "форма начинает падать"
        "decay_warning_xp_v1",     // day 8 — "XP теряется быстрее, уровень под угрозой"
        "decay_warning_level_v1"   // day 14 — "уровень падает, спаси свой пик"
    ]

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

    // MARK: - Decay warnings

    /// Schedules 3 decay-warning notifications relative to the last workout date.
    /// Call this on workout completion AND on app foreground to keep timings fresh.
    /// `peakLevel` is used to personalise the third (level-loss) warning.
    static func rescheduleDecayWarnings(lastWorkoutDate: Date?, peakLevel: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: decayWarningIDs)

        guard let last = lastWorkoutDate else { return }

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral else { return }

            let now = Date()
            let day: TimeInterval = 24 * 60 * 60

            schedule(
                id: decayWarningIDs[0],
                fireAt: last.addingTimeInterval(day * 3),
                title: String(localized: "Форма начинает падать"),
                body: String(localized: "Третий день без зала. XP пошёл вниз — одна тренировка вернёт пик."),
                now: now
            )

            schedule(
                id: decayWarningIDs[1],
                fireAt: last.addingTimeInterval(day * 8),
                title: String(localized: "Уровень под угрозой"),
                body: String(localized: "Неделя без тренировок. Скоро потеряешь уровень — приходи в зал."),
                now: now
            )

            schedule(
                id: decayWarningIDs[2],
                fireAt: last.addingTimeInterval(day * 14),
                title: String(localized: "Уровень упал"),
                body: peakLevel > 1
                    ? String(localized: "Сохраним «ПИК \(peakLevel)» как трофей. Возвращайся — и заберёшь уровень обратно.")
                    : String(localized: "Тело начинает терять адаптацию. Возвращайся в зал."),
                now: now
            )
        }
    }

    private static func schedule(id: String, fireAt: Date, title: String, body: String, now: Date) {
        let interval = fireAt.timeIntervalSince(now)
        guard interval > 60 else { return } // skip if past or too soon

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
