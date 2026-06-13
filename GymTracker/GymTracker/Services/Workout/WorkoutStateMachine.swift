//
//  WorkoutStateMachine.swift
//  GymTracker
//
//  Manages workout state transitions (SRP: Only state logic)
//

import Foundation
import Combine

/// Workout state machine
/// Single Responsibility: Manage workout state transitions
///
/// ⚠️ NOT WIRED INTO THE APP. The live workout flow lives in `WorkoutManager`,
/// which manages `workoutState` directly. This type is only instantiated by the
/// unused `AppDependencies` container. Do not assume transitions route through
/// here — and note its `WorkoutState` cases differ from `WorkoutManager`'s
/// (e.g. no `.briefing`). Either wire it in deliberately or delete it.
@MainActor
final class WorkoutStateMachine: ObservableObject {
    @Published var state: WorkoutState = .idle
    
    func startCountdown() {
        guard state == .idle else { return }
        state = .countdown
    }
    
    func beginWorkout() {
        guard state == .countdown else { return }
        state = .active
    }
    
    func finishWorkout() {
        guard state == .active else { return }
        state = .summary
    }
    
    func reset() {
        state = .idle
    }
    
    var canStartWorkout: Bool {
        state == .idle
    }
    
    var isWorkoutActive: Bool {
        state == .active
    }
}
