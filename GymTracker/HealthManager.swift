import Foundation
import HealthKit
import Combine
import SwiftUI

class HealthManager: NSObject, ObservableObject {
    static let shared = HealthManager()
    
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    
    // Используем Any? для хранения, чтобы компилятор не ругался на типы "iOS 26.0"
    // Using Any? to store sessions/builders safely across SDK versions
    var _session: Any?
    var _builder: Any?
    
    // Real-time callbacks
    var onHeartRateUpdate: ((Int) -> Void)?
    var onCalorieUpdate: ((Int) -> Void)?
    
    private override init() {}
    
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            return false
        }
        
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return false
        }
        let workoutType = HKObjectType.workoutType()
        let activitySummaryType = HKObjectType.activitySummaryType()
        
        let readTypes: Set<HKObjectType> = [
            energyType, 
            hrType, 
            workoutType, 
            activitySummaryType,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        let writeTypes: Set<HKSampleType> = [energyType, workoutType]
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if !success {
                        continuation.resume(throwing: HKError(.errorAuthorizationDenied))
                    } else {
                        continuation.resume()
                    }
                }
            }
            await MainActor.run {
                self.isAuthorized = true
            }
            return true
        } catch {
            print("HealthKit Authorization Failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Workout Session Management
    
    func startWorkout(workoutType: HKWorkoutActivityType) async {
        guard isAuthorized else { return }
        
        // Xcode/SDK is flagging this as iOS 26.0+, wrapping to fix build
        if #available(iOS 26.0, *) {
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = workoutType
            configuration.locationType = .indoor
            
            do {
                let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
                _session = session
                session.delegate = self
                
                session.startActivity(with: Date())
                print("HealthKit Session Started: \(workoutType.rawValue)")
            } catch {
                print("Failed to start Workout Session: \(error.localizedDescription)")
            }
        } else {
             print("HKWorkoutSession not started: requires iOS 26.0+ in this SDK env")
        }
    }
    
    func endWorkout() async {
        if #available(iOS 26.0, *) {
            guard let session = _session as? HKWorkoutSession else { return }
            session.end()
            _session = nil
            print("HealthKit Session Ended")
        }
    }
    
    func discardWorkout() async {
        if #available(iOS 26.0, *) {
            guard let session = _session as? HKWorkoutSession else { return }
            session.end()
            _session = nil
            print("HealthKit Workout Discarded")
        }
    }
    
    // MARK: - Data Fetching
    
    func fetchCaloriesForWorkout(start: Date, end: Date) async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
            guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
                return 0.0
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            
            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: calorieType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                    if let error = error {
                        print("Error fetching calories: \(error.localizedDescription)")
                        continuation.resume(returning: 0.0)
                        return
                    }
                    
                    guard let samples = samples as? [HKQuantitySample] else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    
                    let totalCalories = samples.reduce(0.0) { sum, sample in
                        sum + sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                    }
                    
                    continuation.resume(returning: totalCalories)
                }
                
                store.execute(query)
            }
        }.value
    }
    
    func fetchLatestHeartRate(since start: Date? = nil) async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
             guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
                return 0.0
            }
        
        // If start date is provided, query from there.
        // If nil, look back 1 hour to find the most recent sample.
        let startDate = start ?? Date().addingTimeInterval(-3600)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    print("Error fetching HR: \(error.localizedDescription)")
                    continuation.resume(returning: 0.0)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                continuation.resume(returning: heartRate)
            }
            store.execute(query)
        }
        }.value
    }
    
    func fetchAverageHeartRate(start: Date, end: Date) async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
            guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
                return 0.0
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            
            return await withCheckedContinuation { continuation in
                let statisticsQuery = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, error in
                    if let error = error {
                        print("Error fetching Avg HR: \(error.localizedDescription)")
                        continuation.resume(returning: 0.0)
                        return
                    }
                    
                    guard let result = result, let averageQuantity = result.averageQuantity() else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    
                    let averageHeartRate = averageQuantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    continuation.resume(returning: averageHeartRate)
                }
                
                store.execute(statisticsQuery)
            }
        }.value
    }
    
    func fetchRestingHeartRate() async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
             guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
                return 0.0
            }
            
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                 guard let sample = samples?.first as? HKQuantitySample else { return }
            }
            
            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        print("Error fetching Resting HR: \(error.localizedDescription)")
                        continuation.resume(returning: 0.0)
                        return
                    }
                    
                    guard let sample = samples?.first as? HKQuantitySample else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    
                    let hr = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    continuation.resume(returning: hr)
                }
                store.execute(query)
            }
        }.value
    }

// MARK: - Delegates
// Using Any or conditional conformance is tricky, but extensions usually allow @available
@available(iOS 26.0, *)
extension HealthManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("HKWorkoutSession State Changed: \(toState.rawValue)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("HKWorkoutSession Failed: \(error.localizedDescription)")
    }
}



// MARK: - Steps

extension HealthManager {
    func fetchTodaySteps() async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                continuation.resume(returning: steps)
            }
            healthStore.execute(query)
        }
    }
    
    func fetchTodayDistance() async -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return 0 }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let km = sum.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                continuation.resume(returning: km)
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - Sleep Analysis

struct SleepData: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let type: HKCategoryValueSleepAnalysis
    
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var color: Color {
        switch type {
        case .asleepCore: return Color.blue
        case .asleepDeep: return Color.purple
        case .asleepREM: return Color.cyan
        case .asleepUnspecified: return Color.blue.opacity(0.5)
        case .awake: return Color.orange
        case .inBed: return Color.gray.opacity(0.3)
        @unknown default: return Color.gray
        }
    }
    
    var label: String {
        switch type {
        case .asleepCore: return "Базовый"
        case .asleepDeep: return "Глубокий"
        case .asleepREM: return "Быстрый (REM)"
        case .asleepUnspecified: return "Сон"
        case .awake: return "Бодрствование"
        case .inBed: return "В кровати"
        @unknown default: return "Неизвестно"
        }
    }
}

extension HealthManager {
    func fetchActivitySummary() async -> HKActivitySummary? {
        let store = self.healthStore
        // Create a predicate for today
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.day, .month, .year, .era], from: Date())
        dateComponents.calendar = calendar
        
        let predicate = HKQuery.predicateForActivitySummary(with: dateComponents)
        
        return await withCheckedContinuation { continuation in
            let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
                if let error = error {
                    print("Error fetching activity summary: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let summaries = summaries, let summary = summaries.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: summary)
            }
            
            store.execute(query)
        }
    }

    func fetchSleepData(for date: Date = Date()) async -> [SleepData] {
        let store = self.healthStore
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        
        // Define night range (yesterday 18:00 to today 12:00 to catch full night sleep)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Start: previous day at 18:00
        let queryStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay)! // 18:00 yesterday
        // End: today at 12:00 (noon) to include late morning wake
        let queryEnd = calendar.date(byAdding: .hour, value: 12, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: queryStart, end: queryEnd, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard let samples = samples as? [HKCategorySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Convert to SleepData
                var sleepData = samples.map { sample -> SleepData in
                    SleepData(
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        type: HKCategoryValueSleepAnalysis(rawValue: sample.value) ?? .asleepUnspecified
                    )
                }
                
                // If we have detailed phases (Core/Deep/REM), remove the overall "inBed" segments
                // to avoid double-counting
                let hasDetailedPhases = sleepData.contains { 
                    $0.type == .asleepCore || $0.type == .asleepDeep || $0.type == .asleepREM 
                }
                
                if hasDetailedPhases {
                    sleepData = sleepData.filter { $0.type != .inBed }
                }
                
                continuation.resume(returning: sleepData)
            }
            store.execute(query)
        }
    }
}
