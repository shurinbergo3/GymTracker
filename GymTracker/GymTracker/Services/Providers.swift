import Foundation
import HealthKit

// MARK: - Health Provider Protocol

protocol HealthProvider: AnyObject {
    var isAuthorized: Bool { get }
    var onHeartRateUpdate: ((Int) -> Void)? { get set }
    var onCalorieUpdate: ((Int) -> Void)? { get set }
    
    func requestAuthorization() async -> Bool
    func startWorkout(workoutType: HKWorkoutActivityType) async
    func endWorkout(activityType: HKWorkoutActivityType, startDate: Date?, endDate: Date?) async
    func discardWorkout() async
    
    func fetchCaloriesForWorkout(start: Date, end: Date) async -> Double
    func fetchAverageHeartRate(start: Date, end: Date) async -> Double
    func fetchLatestHeartRate(since start: Date?) async -> Double
}

// MARK: - Activity Provider Protocol

@MainActor
protocol ActivityProvider: AnyObject {
    func start(workoutType: String, startDate: Date)
    func update(heartRate: Int, calories: Int)
    func end()
}
