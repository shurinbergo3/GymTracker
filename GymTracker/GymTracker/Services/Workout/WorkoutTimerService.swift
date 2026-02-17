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
    
    nonisolated private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
    
    nonisolated private func updateDuration() {
        guard let startTime = workoutStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        
        DispatchQueue.main.async { [weak self] in
            self?.workoutDuration = duration
        }
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
    
    nonisolated private func decrementRestTime(_ timer: Timer) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.restTimeRemaining -= 1
            
            if self.restTimeRemaining <= 0 {
                self.stopRestTimer()
            }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopDurationTimer()
        durationTimer?.invalidate()
        restTimer?.invalidate()
    }
}
