//
//  WorkoutTimerService.swift
//  GymTracker
//
//  Manages workout timing (SRP: Only timing logic)
//

import Foundation
import Combine

/// Manages workout timing
/// Single Responsibility: Track workout duration and rest periods
final class WorkoutTimerService: ObservableObject {
    @Published var workoutDuration: TimeInterval = 0
    @Published var restTimeRemaining: Int = 0
    
    private var workoutStartTime: Date?
    private var durationTimer: Timer?
    private var restTimer: Timer?
    
    // MARK: - Workout Timer
    
    func startWorkout() {
        workoutStartTime = Date()
        startDurationTimer()
    }
    
    func stopWorkout() -> TimeInterval {
        stopDurationTimer()
        
        guard let startTime = workoutStartTime else {
            return 0
        }
        
        return Date().timeIntervalSince(startTime)
    }
    
    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDuration()
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
    
    private func updateDuration() {
        guard let startTime = workoutStartTime else { return }
        workoutDuration = Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Rest Timer
    
    func startRestTimer(seconds: Int) {
        restTimeRemaining = seconds
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            self?.decrementRestTime(timer)
        }
    }
    
    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restTimeRemaining = 0
    }
    
    private func decrementRestTime(_ timer: Timer) {
        restTimeRemaining -= 1
        if restTimeRemaining <= 0 {
            stopRestTimer()
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        durationTimer?.invalidate()
        restTimer?.invalidate()
    }
}
