//
//  HealthService.swift
//  GymTracker
//
//  Protocol for HealthKit operations (DIP)
//

import Foundation
import HealthKit

/// Abstraction for HealthKit operations
protocol HealthService {
    /// Request HealthKit authorization
    func requestAuthorization() async -> Bool
    
    /// Start workout tracking
    func startWorkout(workoutType: HKWorkoutActivityType) async
    
    /// End workout and save to HealthKit
    func endWorkout(
        activityType: HKWorkoutActivityType,
        startDate: Date?,
        endDate: Date?
    ) async
    
    /// Discard current workout without saving
    func discardWorkout() async
    
    /// Fetch latest heart rate
    func fetchLatestHeartRate(since start: Date?) async -> Double
    
    /// Fetch calories for workout period
    func fetchCaloriesForWorkout(start: Date, end: Date) async -> Double
    
    /// Check if HealthKit is authorized
    var isAuthorized: Bool { get }
    
    /// Check if workout is currently active
    var isWorkoutActive: Bool { get }
    
    /// Callbacks for live updates
    var onHeartRateUpdate: ((Int) -> Void)? { get set }
    var onCalorieUpdate: ((Int) -> Void)? { get set }
}
