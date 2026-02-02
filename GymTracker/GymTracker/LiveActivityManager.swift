import Foundation
import ActivityKit
import SwiftUI

@MainActor
class LiveActivityManager: ActivityProvider {
    static let shared = LiveActivityManager()
    
    private var activity: Activity<WorkoutAttributes>?
    
    // We keep track of the start date to ensure updates are consistent
    private var workoutStartDate: Date?
    
    // Configuration Constants
    private enum Constants {
        static let throttleInterval: TimeInterval = 2.0
        static let heartRateChangeThreshold: Int = 5
        static let dismissalDelay: UInt64 = 500_000_000 // 0.5 seconds
    }
    
    private init() {}
    
    func start(workoutType: String, startDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = WorkoutAttributes(workoutName: "Training")
        let initialState = WorkoutAttributes.ContentState(
            heartRate: 0,
            calories: 0,
            workoutType: workoutType,
            startTime: startDate
        )
        
        // End any existing activity first
        if activity != nil {
            end()
        }
        
        workoutStartDate = startDate
        
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
        guard let activity = activity, let startDate = workoutStartDate else { return }
        
        if shouldUpdate(heartRate: heartRate) {
            performUpdate(activity: activity, startDate: startDate, heartRate: heartRate, calories: calories)
        }
    }
    
    // Logic to determine if update should be throttled
    private func shouldUpdate(heartRate: Int) -> Bool {
        let now = Date()
        let timeDriven = lastUpdateDate == nil || now.timeIntervalSince(lastUpdateDate!) > Constants.throttleInterval
        let dataDriven = abs(heartRate - lastHeartRate) > Constants.heartRateChangeThreshold
        return timeDriven || dataDriven
    }
    
    private func performUpdate(activity: Activity<WorkoutAttributes>, startDate: Date, heartRate: Int, calories: Int) {
        lastUpdateDate = Date()
        lastHeartRate = heartRate
        lastCalories = calories
        
        let updatedState = WorkoutAttributes.ContentState(
            heartRate: heartRate,
            calories: calories,
            workoutType: activity.content.state.workoutType,
            startTime: startDate
        )
        
        Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }
    
    func end() {
        guard let currentActivity = activity else { return }
        
        // 1. Clear state immediately to prevent race conditions with updates
        resetState()
        
        let finalState = currentActivity.content.state
        
        // 2. End activity with proper dismissal
        Task {
            // First, update to final state
            await currentActivity.update(.init(state: finalState, staleDate: nil))
            
            // Small delay to ensure state is updated before ending
            try? await Task.sleep(nanoseconds: Constants.dismissalDelay)
            
            // Then end with immediate dismissal policy to clear it from lock screen
            await currentActivity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            
            #if DEBUG
            print("✅ Live Activity ended and dismissed")
            #endif
        }
    }
    
    private func resetState() {
        self.activity = nil
        self.workoutStartDate = nil
        self.lastUpdateDate = nil
        self.lastHeartRate = 0
        self.lastCalories = 0
    }
}
