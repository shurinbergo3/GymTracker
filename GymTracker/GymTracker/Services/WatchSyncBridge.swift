//
//  WatchSyncBridge.swift
//  GymTracker (iOS)
//
//  Mirrors workout state (current exercise, rest timer, heart rate, calories)
//  to a paired Apple Watch app via WatchConnectivity.
//
//  Failure mode is silent on purpose: if no watch is paired or no companion
//  watch app is installed, all sends are no-ops. The iOS app keeps working.
//

import Foundation
import WatchConnectivity

/// Snapshot the watch can render. Keep keys stable — they're parsed by string
/// on the watch side.
enum WatchSyncKey {
    static let kind = "kind"            // "state" | "ended"
    static let workoutName = "workout"
    static let exercise = "exercise"
    static let setNumber = "setNumber"
    static let totalSets = "totalSets"
    static let restEndsAt = "restEndsAt" // TimeInterval since 1970, or 0 if not resting
    static let startTime = "startTime"   // TimeInterval since 1970
    static let heartRate = "heartRate"
    static let calories = "calories"
    static let language = "language"     // ISO 639-1 code (ru/en/pl) so the
                                         // watch shows the same language as
                                         // the user picked in iPhone settings.
}

@MainActor
final class WatchSyncBridge: NSObject {
    static let shared = WatchSyncBridge()

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    // Throttle live updates so we don't flood the watch with HR ticks.
    private var lastSentAt: Date = .distantPast
    private let minSendInterval: TimeInterval = 1.0

    private override init() {
        super.init()
    }

    func activate() {
        guard let session = session else { return }
        session.delegate = self
        session.activate()
    }

    func syncCurrentState(from manager: WorkoutManager) {
        guard let session = session, session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else { return }
        guard let workoutSession = manager.currentSession else { return }

        let now = Date()
        if now.timeIntervalSince(lastSentAt) < minSendInterval { return }
        lastSentAt = now

        var payload: [String: Any] = [
            WatchSyncKey.kind: "state",
            WatchSyncKey.workoutName: workoutSession.workoutDayName,
            WatchSyncKey.startTime: workoutSession.date.timeIntervalSince1970,
            WatchSyncKey.heartRate: manager.currentHeartRate,
            WatchSyncKey.calories: manager.currentActiveCalories,
            WatchSyncKey.restEndsAt: manager.restEndsAt?.timeIntervalSince1970 ?? 0,
            WatchSyncKey.language: LanguageManager.shared.currentLanguageCode
        ]
        if let exercise = manager.currentExerciseName {
            payload[WatchSyncKey.exercise] = exercise
        }
        if let setNumber = manager.currentSetNumber {
            payload[WatchSyncKey.setNumber] = setNumber
        }
        if let totalSets = manager.currentTotalSets {
            payload[WatchSyncKey.totalSets] = totalSets
        }

        // updateApplicationContext keeps only the LATEST value — perfect for
        // a "what's on screen right now" snapshot. It also delivers in the
        // background when the watch app is suspended.
        do {
            try session.updateApplicationContext(payload)
        } catch {
            #if DEBUG
            print("WatchSyncBridge: updateApplicationContext failed: \(error)")
            #endif
        }
    }

    func syncWorkoutEnded() {
        guard let session = session, session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else { return }
        let payload: [String: Any] = [WatchSyncKey.kind: "ended"]
        try? session.updateApplicationContext(payload)
        lastSentAt = .distantPast
    }
}

extension WatchSyncBridge: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        #if DEBUG
        if let error = error {
            print("WatchSyncBridge: activation error \(error)")
        } else {
            print("WatchSyncBridge: activation \(activationState.rawValue)")
        }
        #endif
    }

    // iOS-only callbacks — required by the protocol but unused for our mirror flow.
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate so a switched watch can pair without an app restart.
        session.activate()
    }

    // Watch -> iPhone: "Start Workout" tap.
    // We post a NotificationCenter event so WorkoutManager (which owns the
    // SwiftData context + active program logic) can react without this
    // bridge needing a direct reference to it.
    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String : Any],
                             replyHandler: @escaping ([String : Any]) -> Void) {
        handleWatchAction(message)
        replyHandler(["ok": true])
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String : Any]) {
        handleWatchAction(message)
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleWatchAction(userInfo)
    }

    private nonisolated func handleWatchAction(_ payload: [String: Any]) {
        guard let action = payload["action"] as? String else { return }
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: WatchSyncBridge.watchActionNotification,
                object: nil,
                userInfo: ["action": action]
            )
        }
    }

    static let watchActionNotification = Notification.Name("BodyForgeWatchAction")
}
