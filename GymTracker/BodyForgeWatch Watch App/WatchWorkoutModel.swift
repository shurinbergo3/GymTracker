//
//  WatchWorkoutModel.swift
//  Body Forge Watch App
//
//  Receives mirrored workout state from the iPhone and exposes it as
//  @Published values for SwiftUI. Also owns the rest-timer haptic that
//  fires at exactly the moment the iPhone-side rest timer ends.
//

import Foundation
import Combine
import WatchConnectivity
import WatchKit
import SwiftUI

// MARK: - Sync key contract
// Must stay in sync with iOS-side WatchSyncBridge.swift.
private enum WatchSyncKey {
    static let kind = "kind"
    static let workoutName = "workout"
    static let exercise = "exercise"
    static let setNumber = "setNumber"
    static let totalSets = "totalSets"
    static let restEndsAt = "restEndsAt"
    static let startTime = "startTime"
    static let heartRate = "heartRate"
    static let calories = "calories"
    static let language = "language"
    static let totalWorkouts = "totalWorkouts"
    static let workoutsThisWeek = "workoutsThisWeek"
    static let weeklyGoal = "weeklyGoal"
    static let lastWorkoutDate = "lastWorkoutDate"
}

@MainActor
final class WatchWorkoutModel: NSObject, ObservableObject {
    @Published var isWorkoutActive: Bool = false

    @Published var workoutName: String = ""
    @Published var exerciseName: String?
    @Published var setNumber: Int?
    @Published var totalSets: Int?
    @Published var startTime: Date?
    @Published var restEndsAt: Date?
    @Published var heartRate: Int = 0
    @Published var calories: Int = 0

    /// Language code (ru/en/pl/...) the iPhone-side `LanguageManager` is
    /// currently set to. Until we get the first state push, fall back to the
    /// watch's own system locale so brand-new users still see something
    /// sensible.
    @Published var languageCode: String = Locale.current.language.languageCode?.identifier ?? "en"

    /// Stats shown on the idle screen above the Start button. Populated from
    /// the iPhone's "idle" / "ended" payloads. nil until the iPhone has at
    /// least sent one snapshot.
    @Published var idleStats: IdleStats?

    struct IdleStats: Equatable {
        let totalWorkouts: Int
        let workoutsThisWeek: Int
        let weeklyGoal: Int
        let lastWorkoutDate: Date?
    }

    /// Helper used by the rest-timer haptic so we don't fire the buzz twice
    /// when the same `restEndsAt` arrives via two messages.
    private var lastFiredRestEndsAt: Date?

    /// Async task that fires the local watch haptic at the precise moment
    /// the rest period ends — independent of the next state push from the
    /// phone. Cancelled on rest end / new rest start / workout end.
    private var restCompletionTask: Task<Void, Never>?

    var isResting: Bool {
        guard let restEndsAt else { return false }
        return restEndsAt > Date()
    }

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            // Pick up any state that was sent while the watch app was suspended.
            applyContext(WCSession.default.receivedApplicationContext)
        }
    }

    // MARK: - State application

    private func applyContext(_ context: [String: Any]) {
        guard !context.isEmpty else { return }

        // Always pick up language if present — applies to every payload kind.
        if let lang = context[WatchSyncKey.language] as? String, !lang.isEmpty {
            languageCode = lang
        }

        // Idle stats can ride on either a dedicated "idle" payload (sent at
        // launch) or piggy-back on "ended" (sent when a workout finishes so
        // the bumped count shows up immediately).
        let kind = context[WatchSyncKey.kind] as? String
        if kind == "idle" || kind == "ended" {
            applyIdleStats(from: context)
        }

        if kind == "ended" {
            handleWorkoutEnded()
            return
        }
        if kind == "idle" {
            // Make sure we render the idle screen.
            isWorkoutActive = false
            cancelRestCompletionTimer()
            return
        }

        isWorkoutActive = true
        workoutName = context[WatchSyncKey.workoutName] as? String ?? workoutName
        exerciseName = context[WatchSyncKey.exercise] as? String
        setNumber = context[WatchSyncKey.setNumber] as? Int
        totalSets = context[WatchSyncKey.totalSets] as? Int

        if let startInterval = context[WatchSyncKey.startTime] as? TimeInterval, startInterval > 0 {
            startTime = Date(timeIntervalSince1970: startInterval)
        }

        if let restInterval = context[WatchSyncKey.restEndsAt] as? TimeInterval, restInterval > 0 {
            restEndsAt = Date(timeIntervalSince1970: restInterval)
        } else {
            restEndsAt = nil
            cancelRestCompletionTimer()
        }

        if let hr = context[WatchSyncKey.heartRate] as? Int { heartRate = hr }
        if let cal = context[WatchSyncKey.calories] as? Int { calories = cal }

        scheduleRestCompletionHapticIfNeeded()
    }

    private func applyIdleStats(from context: [String: Any]) {
        let total = context[WatchSyncKey.totalWorkouts] as? Int ?? 0
        let week = context[WatchSyncKey.workoutsThisWeek] as? Int ?? 0
        let goal = context[WatchSyncKey.weeklyGoal] as? Int ?? 0
        let lastInterval = context[WatchSyncKey.lastWorkoutDate] as? TimeInterval ?? 0
        let last = lastInterval > 0 ? Date(timeIntervalSince1970: lastInterval) : nil
        idleStats = IdleStats(
            totalWorkouts: total,
            workoutsThisWeek: week,
            weeklyGoal: goal,
            lastWorkoutDate: last
        )
    }

    // MARK: - Localization
    //
    // The watch is sandboxed from the iOS app's Localizable.xcstrings, so we
    // hand-translate the few strings that actually appear on the watch UI.
    // The `languageCode` is reactive (`@Published`) so SwiftUI auto-rebuilds
    // when the iPhone pushes a new language.

    func t(en: String, ru: String, pl: String) -> String {
        switch languageCode {
        case "ru": return ru
        case "pl": return pl
        default: return en
        }
    }

    // MARK: - Reverse channel (watch → iPhone)

    /// "Start Workout" tap on the watch. Sends a fire-and-forget message to
    /// the iPhone, which wakes the iOS app long enough to start the active
    /// program's selected day. iOS API doesn't let us bring the iPhone app
    /// to foreground from the watch — but Live Activity will surface on the
    /// iPhone's lock screen / Dynamic Island once the workout starts.
    @Published private(set) var startSignalState: StartSignalState = .idle

    enum StartSignalState: Equatable {
        case idle
        case sending
        case sent
        case failed(String)
    }

    func requestStartWorkout() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else {
            // Watch can still send via transferUserInfo (delivered when iPhone
            // wakes), but optimistically mark sent — user gets feedback.
            sendStartUserInfo()
            return
        }

        WKInterfaceDevice.current().play(.click)
        startSignalState = .sending

        session.sendMessage(["action": "startWorkout"], replyHandler: { [weak self] _ in
            Task { @MainActor in
                self?.startSignalState = .sent
                WKInterfaceDevice.current().play(.success)
                self?.resetStartSignalAfterDelay()
            }
        }, errorHandler: { [weak self] error in
            Task { @MainActor in
                // Fall back to background-deliverable channel.
                self?.sendStartUserInfo()
                self?.startSignalState = .failed(error.localizedDescription)
                self?.resetStartSignalAfterDelay()
            }
        })
    }

    private func sendStartUserInfo() {
        startSignalState = .sending
        WCSession.default.transferUserInfo(["action": "startWorkout"])
        startSignalState = .sent
        WKInterfaceDevice.current().play(.success)
        resetStartSignalAfterDelay()
    }

    private func resetStartSignalAfterDelay() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            self?.startSignalState = .idle
        }
    }

    private func handleWorkoutEnded() {
        isWorkoutActive = false
        exerciseName = nil
        setNumber = nil
        totalSets = nil
        restEndsAt = nil
        heartRate = 0
        calories = 0
        cancelRestCompletionTimer()
    }

    // MARK: - Rest haptic

    private func scheduleRestCompletionHapticIfNeeded() {
        cancelRestCompletionTimer()
        guard let restEndsAt, restEndsAt > Date() else { return }
        if lastFiredRestEndsAt == restEndsAt { return }

        let delay = restEndsAt.timeIntervalSinceNow
        let endDate = restEndsAt
        restCompletionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(max(0, delay) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.fireRestCompletedHaptic(for: endDate)
        }
    }

    private func cancelRestCompletionTimer() {
        restCompletionTask?.cancel()
        restCompletionTask = nil
    }

    private func fireRestCompletedHaptic(for endDate: Date) {
        lastFiredRestEndsAt = endDate
        // .notification is a strong, attention-grabbing pattern that's audible
        // through clothing — appropriate for "rest is over, get up and lift".
        // No audio is played: the rule is haptic-only.
        WKInterfaceDevice.current().play(.notification)
    }
}

// MARK: - WCSessionDelegate

extension WatchWorkoutModel: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        // Apply whatever the phone sent before activation finished.
        let context = session.receivedApplicationContext
        Task { @MainActor in
            self.applyContext(context)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            self.applyContext(applicationContext)
        }
    }
}
