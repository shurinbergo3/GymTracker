//
//  AICoachNotificationService.swift
//  GymTracker
//
//  AI-coach driven local notifications.
//
//  Pushes that live here:
//  • Smart workout reminders — based on the user's typical training time, fire
//    a "ready when you are" nudge ~30 min before. Predicted from the last 14
//    days of WorkoutSession data; if there's no pattern yet we stay silent.
//  • Streak-milestone celebrations — fired right after a workout that lands
//    on a 5/10/20/50/100-day streak number.
//  • Weekly wrapped — the Sunday-evening recap reminder.
//
//  Recovery alerts (the "go light today" morning push) live in
//  MorningReadinessNudgeService instead: they belong with the green morning
//  nudge so the two share the readiness gate, the morning window, and one
//  frequency cap rather than firing a guessed "tomorrow 9 AM" alert from here.
//
//  Everything respects the master switch `aiCoach.pushEnabled` (Settings →
//  AI Coach → "Push-уведомления от ИИ"). When the user disables it, all
//  AI-coach notification IDs get cancelled wholesale.
//
//  Implementation notes:
//  • We don't call Groq from here — every body text is templated locally so
//    pushes fire reliably with no network dependency. The AI's role is to
//    use the same data inside the next chat reply.
//  • Each category has stable IDs so re-scheduling is idempotent.
//

import Foundation
import SwiftData
@preconcurrency import UserNotifications

@MainActor
enum AICoachNotificationService {

    // MARK: - IDs (stable so re-scheduling is idempotent)

    private static let smartReminderID = "ai.coach.smartReminder.v1"
    private static let weeklyWrappedID = "ai.coach.weeklyWrapped.v1"
    /// Every streak-milestone notification gets a unique ID per milestone so
    /// we don't overwrite a still-pending one and so the user sees each.
    private static func streakID(_ days: Int) -> String { "ai.coach.streak.\(days).v1" }

    /// Cancel every AI-coach push we've ever scheduled. Called from the
    /// Settings toggle when the user disables AI pushes.
    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        Task {
            let requests = await center.pendingNotificationRequests()
            let ids = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix("ai.coach.") }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Master switch

    /// True if the user has opted-in (default true) AND the system grants pushes.
    private static func canPostAsync() async -> Bool {
        let userOptIn = UserDefaults.standard.object(forKey: AICoachPrefs.kAIPushEnabled) as? Bool ?? true
        guard userOptIn else { return false }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    // MARK: - Public entry points

    /// Idempotent: predict the user's next workout window from history and
    /// schedule a single nudge ~30 min before. No-op if we don't have enough
    /// data yet (need at least 4 sessions in the last 14 days). Call from app
    /// foreground and after each finished workout.
    static func rescheduleSmartReminder(modelContext: ModelContext) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [smartReminderID])

        guard await canPostAsync() else { return }

        guard let prediction = predictNextWorkout(modelContext: modelContext) else {
            return
        }

        // Already trained today? Don't bug them again the same day.
        if Calendar.current.isDateInToday(prediction.fireDate) {
            let twoHoursAgo = Date().addingTimeInterval(-2 * 3600)
            let descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate { $0.date >= twoHoursAgo },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let recent = (try? modelContext.fetch(descriptor)) ?? []
            if !recent.isEmpty { return }
        }

        let content = UNMutableNotificationContent()
        content.title = "Время тренироваться".localized()
        content.body = "По твоему расписанию — самое то для зала. Открой план, разберём вместе.".localized()
        content.sound = .default
        content.categoryIdentifier = "ai_coach_reminder"

        let interval = prediction.fireDate.timeIntervalSinceNow
        guard interval > 60 else { return }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: smartReminderID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    /// Fire a delayed celebratory push if the just-completed workout pushed the
    /// user onto a milestone streak number. Pushes 30 s out so the in-app
    /// summary screen is seen first, then the notification reinforces it.
    static func celebrateStreakIfMilestone(streakDays: Int) async {
        let milestones: Set<Int> = [3, 5, 7, 10, 14, 20, 30, 50, 75, 100, 150, 200, 365]
        guard milestones.contains(streakDays) else { return }
        guard await canPostAsync() else { return }

        let id = streakID(streakDays)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = String(format: "🔥 %d дней подряд".localized(), streakDays)
        content.body = streakBody(for: streakDays)
        content.sound = .default
        content.categoryIdentifier = "ai_coach_streak"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // MARK: - Heuristics

    /// Predicts the next workout time from the last 14 days of sessions.
    /// Returns nil if there's not enough signal (need ≥ 4 sessions).
    private static func predictNextWorkout(modelContext: ModelContext) -> (fireDate: Date, dayName: String)? {
        let lookback = Date().addingTimeInterval(-14 * 24 * 3600)
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.date >= lookback },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let sessions = try? modelContext.fetch(descriptor), sessions.count >= 4 else {
            return nil
        }

        let cal = Calendar.current
        // Most common training weekday (1 = Sunday on Apple's calendar).
        var weekdayCounts: [Int: Int] = [:]
        var hourSum: Int = 0
        for s in sessions {
            let wd = cal.component(.weekday, from: s.date)
            let h = cal.component(.hour, from: s.date)
            weekdayCounts[wd, default: 0] += 1
            hourSum += h
        }
        let avgHour = hourSum / sessions.count

        // Find the next weekday in the user's pattern (any weekday they trained ≥ 2 times).
        let popularDays = Set(weekdayCounts.filter { $0.value >= 2 }.map { $0.key })
        guard !popularDays.isEmpty else { return nil }

        let now = Date()
        for offset in 0..<7 {
            guard let candidate = cal.date(byAdding: .day, value: offset, to: now) else { continue }
            let wd = cal.component(.weekday, from: candidate)
            guard popularDays.contains(wd) else { continue }
            // Build a Date at avgHour:00 on that weekday, then back off 30 min.
            var comps = cal.dateComponents([.year, .month, .day], from: candidate)
            comps.hour = avgHour
            comps.minute = 0
            guard let target = cal.date(from: comps) else { continue }
            let fireAt = target.addingTimeInterval(-30 * 60)
            if fireAt > now.addingTimeInterval(60) {
                let dayName = cal.weekdaySymbols[max(0, wd - 1)]
                return (fireAt, dayName)
            }
        }
        return nil
    }

    /// Re-schedules the weekly wrapped reminder for the next upcoming Sunday at
    /// 19:00 local time. Idempotent — safe to call from app launch and from
    /// any flow that touches notification preferences.
    static func rescheduleWeeklyWrappedPush() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [weeklyWrappedID])
        guard await canPostAsync() else { return }

        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        // Apple weekday: 1=Sun. Find the closest upcoming Sunday at 19:00.
        var fire: Date?
        for offset in 0...7 {
            guard let day = cal.date(byAdding: .day, value: offset, to: now) else { continue }
            if cal.component(.weekday, from: day) == 1 {
                var c = cal.dateComponents([.year, .month, .day], from: day)
                c.hour = 19; c.minute = 0
                if let d = cal.date(from: c), d > now.addingTimeInterval(60) {
                    fire = d
                    break
                }
            }
        }
        guard let fire else { return }

        let content = UNMutableNotificationContent()
        content.title = "Твоя неделя готова".localized()
        content.body = "Тоннаж, рекорды, серия — всё в одном экране. Сохрани и поделись.".localized()
        content.sound = .default
        content.categoryIdentifier = "ai_coach_wrapped"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fire.timeIntervalSinceNow, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: weeklyWrappedID, content: content, trigger: trigger))
    }

    // MARK: - Streak helper

    /// Counts consecutive training days back from today (inclusive if trained today).
    /// Mirrors the logic in `WeeklyStreakStrip.streak` so the two never disagree.
    static func currentStreakDays(modelContext: ModelContext) -> Int {
        let lookback = Date().addingTimeInterval(-200 * 24 * 3600)
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.date >= lookback },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let sessions = try? modelContext.fetch(descriptor) else { return 0 }
        let cal = Calendar.current
        let trained = Set(sessions.map { cal.startOfDay(for: $0.date) })

        var current = cal.startOfDay(for: Date())
        if !trained.contains(current) {
            guard let y = cal.date(byAdding: .day, value: -1, to: current) else { return 0 }
            current = y
        }
        var count = 0
        while trained.contains(current) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }
        return count
    }

    // MARK: - Streak copy

    private static func streakBody(for days: Int) -> String {
        switch days {
        case ..<7:   return "Серия растёт. Завтра — ещё одна.".localized()
        case 7..<14: return "Неделя без пропусков. Это уже привычка.".localized()
        case 14..<30: return "Две недели подряд — твоя дисциплина даёт результат.".localized()
        case 30..<100: return "Месячная серия. Это уровень атлета.".localized()
        default:      return "Сотня тренировок без пропусков — редкая лига.".localized()
        }
    }
}
