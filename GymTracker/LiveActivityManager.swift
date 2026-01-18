import Foundation
import ActivityKit
import SwiftUI

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var activity: Activity<WorkoutAttributes>?
    
    // We keep track of the start date to ensure updates are consistent
    private var workoutStartDate: Date?
    
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
            print("Live Activity started: \(activity?.id ?? "")")
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    private var lastUpdateDate: Date?
    private var lastHeartRate: Int = 0
    private var lastCalories: Int = 0
    
    // Configurable throttle interval
    private let throttleInterval: TimeInterval = 2.0
    
    func update(heartRate: Int, calories: Int) {
        guard let activity = activity, let startDate = workoutStartDate else { return }
        
        let now = Date()
        
        // Throttling logic:
        // Update if:
        // 1. First update (lastUpdateDate is nil)
        // 2. Time since last update > throttleInterval
        // 3. Significant change in Heart Rate (> 5 BPM)
        
        let timeDriven = lastUpdateDate == nil || now.timeIntervalSince(lastUpdateDate!) > throttleInterval
        let dataDriven = abs(heartRate - lastHeartRate) > 5
        
        guard timeDriven || dataDriven else { return }
        
        lastUpdateDate = now
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
        self.activity = nil
        self.workoutStartDate = nil
        self.lastUpdateDate = nil
        self.lastHeartRate = 0
        self.lastCalories = 0
        
        let finalState = currentActivity.content.state
        
        // 2. Perform the async system call
        Task {
            await currentActivity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            print("Live Activity ended")
        }
    }
}
