import Foundation
import ActivityKit
import SwiftUI

@MainActor
class LiveActivityManager: ActivityProvider {
    static let shared = LiveActivityManager()

    private var activity: Activity<WorkoutAttributes>?

    // We keep track of the start date to ensure updates are consistent
    private var workoutStartDate: Date?

    // Last applied state — used so partial updates (rest, exercise, HR) don't
    // wipe each other out.
    private var currentState: WorkoutAttributes.ContentState?

    // Configuration Constants
    private enum Constants {
        static let throttleInterval: TimeInterval = 2.0
        static let heartRateChangeThreshold: Int = 5
    }

    private init() {}

    func start(workoutType: String, startDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = WorkoutAttributes(workoutName: "Training")
        let initialState = WorkoutAttributes.ContentState(
            heartRate: 0,
            calories: 0,
            workoutType: workoutType,
            startTime: startDate,
            currentExerciseName: nil,
            setNumber: nil,
            totalSets: nil,
            restEndsAt: nil,
            languageCode: LanguageManager.shared.currentLanguageCode
        )

        // End any existing activity first
        if activity != nil {
            end()
        }

        workoutStartDate = startDate
        currentState = initialState

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil)
            )
            #if DEBUG
            print("Live Activity started: \(activity?.id ?? "")")
            #endif
        } catch {
            #if DEBUG
            print("Error starting Live Activity: \(error.localizedDescription)")
            #endif
        }
    }

    private var lastUpdateDate: Date?
    private var lastHeartRate: Int = 0
    private var lastCalories: Int = 0

    func update(heartRate: Int, calories: Int) {
        guard activity != nil, var state = currentState else { return }

        let caloriesChanged = abs(calories - lastCalories) > 5

        if shouldUpdate(heartRate: heartRate) || caloriesChanged {
            state.heartRate = heartRate
            state.calories = calories
            // Cheap to refresh — picks up an in-workout language switch.
            state.languageCode = LanguageManager.shared.currentLanguageCode
            lastUpdateDate = Date()
            lastHeartRate = heartRate
            lastCalories = calories
            apply(state)
        }
    }

    func updateExercise(name: String?, setNumber: Int?, totalSets: Int?) {
        guard activity != nil, var state = currentState else { return }
        state.currentExerciseName = name
        state.setNumber = setNumber
        state.totalSets = totalSets
        apply(state)
    }

    func startRest(until endDate: Date) {
        guard activity != nil, var state = currentState else { return }
        state.restEndsAt = endDate
        apply(state)
    }

    func endRest() {
        guard activity != nil, var state = currentState else { return }
        state.restEndsAt = nil
        apply(state)
    }

    private func shouldUpdate(heartRate: Int) -> Bool {
        let now = Date()
        let timeDriven = lastUpdateDate == nil || now.timeIntervalSince(lastUpdateDate!) > Constants.throttleInterval
        let dataDriven = abs(heartRate - lastHeartRate) > Constants.heartRateChangeThreshold
        return timeDriven || dataDriven
    }

    private func apply(_ state: WorkoutAttributes.ContentState) {
        currentState = state
        guard let activity = activity else { return }
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    func end() {
        guard let currentActivity = activity else { return }

        let finalState = currentState ?? currentActivity.content.state
        resetState()

        Task {
            // End with immediate dismissal policy to clear it from lock screen INSTANTLY
            await currentActivity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)

            #if DEBUG
            print("✅ Live Activity ended and dismissed immediately")
            #endif
        }
    }

    private func resetState() {
        self.activity = nil
        self.workoutStartDate = nil
        self.currentState = nil
        self.lastUpdateDate = nil
        self.lastHeartRate = 0
        self.lastCalories = 0
    }
}
