//
//  MorningReadinessNudgeService.swift
//  GymTracker
//
//  The morning recovery nudge — the hybrid the rest of the AI-coach pushes
//  aren't. Runs in the background via BGAppRefreshTask, reads the user's
//  recovery WITHOUT them opening the app (HealthKit background reads), and
//  speaks only when the readiness gate is decisive: GREEN → "go train, you're
//  fresh" (solid sleep + low personalised stress), RED → "go light or rest"
//  (poor recovery). AMBER stays silent. Both share one frequency cap so the
//  user gets at most one of them. The body text is written live by the model
//  (GroqClient) with a localized template fallback when the network or sign-in
//  isn't there, so the push always lands.
//
//  Frequency: at most once every 2–4 days (randomised so it never feels
//  robotic). Respects the same master switch as every other AI push
//  (`aiCoach.pushEnabled`).
//
//  iOS reality check: BGAppRefreshTask timing isn't guaranteed — the system
//  runs it opportunistically around `earliestBeginDate` based on how the user
//  uses the app. We schedule for the next morning and re-schedule on every
//  background transition, which is the standard, honest approach.
//

import Foundation
import BackgroundTasks
import FirebaseAuth
@preconcurrency import UserNotifications

@MainActor
enum MorningReadinessNudgeService {

    /// Must match the entry in Info.plist → BGTaskSchedulerPermittedIdentifiers.
    static let taskIdentifier = "ai.coach.morningNudge"
    private static let firedNotificationID = "ai.coach.morningNudge.fired"
    private static let recoveryFiredID = "ai.coach.morningRecovery.fired"

    private static let kNextEligible = "ai.coach.morningNudge.nextEligibleAt"

    /// Only fire inside the morning window (local hours).
    private static let morningStartHour = 6
    private static let morningEndHour = 11

    // MARK: - Registration & scheduling

    /// Registers the BG task handler. MUST be called before the app finishes
    /// launching (from `AppDelegate.didFinishLaunchingWithOptions`).
    nonisolated static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            let work = Task { @MainActor in
                await handle(task: refreshTask)
            }
            refreshTask.expirationHandler = { work.cancel() }
        }
    }

    /// Schedules the next morning refresh. Idempotent. No-op (and cancels any
    /// pending request) when the user has AI pushes turned off.
    static func scheduleNext() {
        guard isOptedIn else { cancel(); return }
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = nextMorningDate()
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            #if DEBUG
            print("⚠️ MorningNudge: BG submit failed: \(error)")
            #endif
        }
    }

    static func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
    }

    // MARK: - Background entry point

    static func handle(task: BGAppRefreshTask) async {
        // Schedule the following day up front, so an expiry/crash still leaves
        // a future task queued.
        scheduleNext()
        _ = await runCheckAndMaybeNudge()
        task.setTaskCompleted(success: !Task.isCancelled)
    }

    /// Public so the app can opportunistically run the same check when it comes
    /// to the foreground in the morning (a free fallback for when iOS throttles
    /// the background task). Returns true if a nudge was posted.
    @discardableResult
    static func runCheckAndMaybeNudge() async -> Bool {
        guard isOptedIn else { return false }
        guard await notificationsAllowed() else { return false }

        let now = Date()

        // Frequency gate — at most once every 2–4 days.
        if let next = UserDefaults.standard.object(forKey: kNextEligible) as? Date, now < next {
            return false
        }

        // Morning window only.
        let hour = Calendar.current.component(.hour, from: now)
        guard hour >= morningStartHour, hour < morningEndHour else { return false }

        // Read recovery (drives both the green and red verdict). On a cold
        // background relaunch the in-memory auth flag is false even though the
        // system grant persists — re-establish it (no UI can appear in the
        // background) before reading.
        if !HealthManager.shared.isAuthorized {
            _ = await HealthManager.shared.requestAuthorization()
        }
        guard HealthManager.shared.isAuthorized else { return false }
        let report = await StressService.shared.loadReport(days: 30)
        guard report.hasData, let headline = report.headline else { return false }

        // The reading must be fresh (today or last night).
        let dayGap = Calendar.current.dateComponents([.day], from: headline.date, to: now).day ?? 99
        guard dayGap <= 1 else { return false }

        // Last night's sleep — optional. Missing data must NOT collapse to "0h"
        // (that would trip a false poor-recovery alert), so we pass nil when
        // absent and let the readiness gate decide on stress alone.
        let sleepHist = await SleepService.shared.fetchSleepHistory(for: .week)
        let lastNight = sleepHist.max(by: { $0.date < $1.date })
        let sleepHours: Double? = (lastNight?.totalDuration ?? 0) > 0 ? lastNight!.totalDuration / 3600 : nil

        // Single source of truth: the SAME readiness gate the rest of the coach
        // uses, so a morning push can never contradict the in-app verdict.
        // green → "go train, you're fresh"; red → "go light/rest"; amber → silent.
        let health = minimalHealthSummary(report: report, sleepHours: sleepHours)
        let readiness = AICoachContextBuilder.assessReadiness(health: health, recentPain: false)

        switch readiness.level {
        case .green:
            // "You slept well" must be true — require solid sleep + low strain.
            guard let sleptWell = sleepHours, sleptWell >= 6.5 else { return false }
            guard headline.band == .calm || headline.band == .balanced else { return false }
            await postNudge(sleepHours: sleptWell, band: headline.band, score: headline.score)
        case .red:
            await postRecoveryAlert(sleepHours: sleepHours, band: headline.band, score: headline.score)
        case .amber:
            return false
        }

        markFired()
        return true
    }

    // MARK: - Gates

    private static var isOptedIn: Bool {
        UserDefaults.standard.object(forKey: AICoachPrefs.kAIPushEnabled) as? Bool ?? true
    }

    private static func notificationsAllowed() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    // MARK: - Notification

    private static func postNudge(sleepHours: Double, band: StressBand, score: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Отличное утро для зала".localized()
        content.body = await nudgeBody(sleepHours: sleepHours, band: band, score: score)
        content.sound = .default
        content.categoryIdentifier = "ai_coach_morning"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: firedNotificationID, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Recovery alert (poor-recovery counterpart of the morning nudge)

    private static func postRecoveryAlert(sleepHours: Double?, band: StressBand, score: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Сегодня - полегче".localized()
        content.body = await recoveryBody(sleepHours: sleepHours, band: band, score: score)
        content.sound = .default
        content.categoryIdentifier = "ai_coach_recovery"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: recoveryFiredID, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private static func recoveryBody(sleepHours: Double?, band: StressBand, score: Int) async -> String {
        if let ai = await aiRecoveryText(sleepHours: sleepHours, band: band, score: score) {
            return ai
        }
        return "Восстановление просело: дай телу передышку. Лёгкая сессия или отдых - и завтра вернёшься сильнее.".localized()
    }

    private static func aiRecoveryText(sleepHours: Double?, band: StressBand, score: Int) async -> String? {
        guard Auth.auth().currentUser != nil else { return nil }

        let lang = appLanguageName()
        let system = GroqMessage(role: .system, content: """
            You write a single short morning push notification for a gym app. The user's recovery looks \
            POOR today (high strain and/or short sleep) and you gently suggest going lighter or taking \
            a rest day — caring and supportive, never alarming, never guilt-tripping. Rules: ONE \
            sentence, max 16 words, warm, no hashtags, at most one emoji, no surrounding quotes. \
            Reply ONLY in \(lang).
            """)
        let sleepTxt = sleepHours.map { String(format: "slept %.1fh last night, ", $0) } ?? ""
        let user = GroqMessage(role: .user, content: """
            Signals: \(sleepTxt)personalised recovery/stress index \(score)/100 \
            (\(band.promptTag), high strain). Write the go-light nudge.
            """)

        do {
            let text = try await withTimeout(seconds: 12) {
                try await GroqClient.shared.complete(messages: [system, user], temperature: 0.7, maxTokens: 500)
            }
            let cleaned = text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            return cleaned.isEmpty ? nil : cleaned
        } catch {
            return nil
        }
    }

    private static func nudgeBody(sleepHours: Double, band: StressBand, score: Int) async -> String {
        if let ai = await aiNudgeText(sleepHours: sleepHours, band: band, score: score) {
            return ai
        }
        return "Ты отлично восстановился: сон в норме, сил полно. Сегодня - идеальный день размяться.".localized()
    }

    /// Live model text. Tight timeout + nil on any failure → caller falls back
    /// to the template, so a slow/absent network never blocks the push.
    private static func aiNudgeText(sleepHours: Double, band: StressBand, score: Int) async -> String? {
        guard Auth.auth().currentUser != nil else { return nil }

        let lang = appLanguageName()
        let system = GroqMessage(role: .system, content: """
            You write a single short morning push notification for a gym app. The user's recovery looks \
            great today and you are gently nudging them to train — never pushy, never guilt-tripping. \
            Rules: ONE sentence, max 16 words, warm and motivating, no hashtags, at most one emoji, \
            no surrounding quotes. Reply ONLY in \(lang).
            """)
        let hrs = String(format: "%.1f", sleepHours)
        let user = GroqMessage(role: .user, content: """
            Signals: slept \(hrs)h last night, personalised recovery/stress index \(score)/100 \
            (\(band.promptTag), low strain). Write the nudge.
            """)

        do {
            let text = try await withTimeout(seconds: 12) {
                try await GroqClient.shared.complete(messages: [system, user], temperature: 0.7, maxTokens: 500)
            }
            let cleaned = text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            return cleaned.isEmpty ? nil : cleaned
        } catch {
            return nil
        }
    }

    // MARK: - Helpers

    private static func minimalHealthSummary(report: StressReport, sleepHours: Double?) -> AICoachContext.HealthSummary {
        let h = report.headline
        return AICoachContext.HealthSummary(
            restingHeartRate: nil,
            last7DaysSteps: nil,
            last7DaysWorkouts: nil,
            lastNightSleepHours: sleepHours,
            weeklySleepAvgHours: nil,
            hrvSDNNms: nil,
            vo2MaxMlKgMin: nil,
            bmi: nil,
            last7DaysExerciseMinutes: nil,
            restingEnergyTodayKcal: nil,
            stressScore: h?.score,
            stressBand: h?.band.promptTag,
            stress30dAvg: report.monthAverage,
            stressTrend: report.trend.promptTag,
            stressDrivers: nil
        )
    }

    private static func markFired() {
        let now = Date()
        let gapDays = Double(Int.random(in: 2...4))
        UserDefaults.standard.set(now.addingTimeInterval(gapDays * 86_400), forKey: kNextEligible)
    }

    private static func nextMorningDate() -> Date {
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.hour = 7
        comps.minute = 30
        let todayMorning = cal.date(from: comps) ?? now
        if todayMorning > now.addingTimeInterval(60) { return todayMorning }
        return cal.date(byAdding: .day, value: 1, to: todayMorning) ?? now.addingTimeInterval(3600)
    }

    private static func appLanguageName() -> String {
        let id = LanguageManager.shared.currentLocale.identifier.lowercased()
        if id.hasPrefix("ru") { return "Russian" }
        if id.hasPrefix("pl") { return "Polish" }
        if id.hasPrefix("de") { return "German" }
        return "English"
    }

    private static func withTimeout<T: Sendable>(seconds: Double,
                                                 _ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CancellationError()
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
