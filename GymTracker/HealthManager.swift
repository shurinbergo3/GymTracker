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
        
        // Xcode/SDK требует проверки на iOS 26.0 для этих API
        // This odd check is required because the current SDK flags these as iOS 26.0+
        if #available(iOS 26.0, *) {
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = workoutType
            configuration.locationType = .indoor
            
            do {
                let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
                _session = session
                
                let builder = session.associatedWorkoutBuilder()
                _builder = builder
                
                builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
                
                session.delegate = self
                builder.delegate = self
                
                session.startActivity(with: Date())
                
                // Fix for missing argument 'completion' in beginCollection
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                   builder.beginCollection(withStart: Date()) { success, error in
                       if let error = error {
                           continuation.resume(throwing: error)
                       } else {
                           continuation.resume()
                       }
                   }
                }
                
                print("HealthKit Session Started (iOS 26+): \(workoutType.rawValue)")
            } catch {
                print("Failed to start Workout Session: \(error.localizedDescription)")
            }
        } else {
            print("Skipping Live Workout Session: APIs require iOS 26.0 in this environment.")
        }
    }
    
    func endWorkout() async {
        if #available(iOS 26.0, *) {
            guard let session = _session as? HKWorkoutSession,
                  let builder = _builder as? HKLiveWorkoutBuilder else { return }
            
            session.end()
            
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    builder.endCollection(withEnd: Date()) { success, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
                if let workout = try await builder.finishWorkout() {
                    print("HealthKit Workout Finished: \(workout.duration)s")
                } else {
                    print("HealthKit Workout Finished (No workout object)")
                }
            } catch {
                print("Failed to finish builder: \(error.localizedDescription)")
            }
            
            _session = nil
            _builder = nil
        }
    }
    
    func discardWorkout() async {
        if #available(iOS 26.0, *) {
            guard let session = _session as? HKWorkoutSession,
                  let builder = _builder as? HKLiveWorkoutBuilder else { return }
            
            session.end()
            builder.discardWorkout()
            
            _session = nil
            _builder = nil
            
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
    
    func fetchLatestHeartRate(since start: Date) async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
             guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
                return 0.0
            }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
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

@available(iOS 26.0, *)
extension HealthManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            // Real-time Heart Rate
            if quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                if let heartRateUnit = statistics?.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) {
                    let hr = Int(heartRateUnit)
                    // Notify listeners (UI/Widget) via MainActor
                    Task { @MainActor in
                        self.onHeartRateUpdate?(hr)
                    }
                }
            }
            
            // Real-time Calories
            if quantityType == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                if let sum = statistics?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) {
                    let cals = Int(sum)
                    // Notify listeners
                    Task { @MainActor in
                        self.onCalorieUpdate?(cals)
                    }
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
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
        
        // Define day range (yesterday 18:00 to today 18:00 to catch full night)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Predicate
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay.addingTimeInterval(-6 * 3600), end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard let samples = samples as? [HKCategorySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Filter out "InBed" overlap if we have detailed phases, or keep them if that's all we have.
                // Generally we want to visualize phases.
                let sleepData = samples.map { sample -> SleepData in
                    SleepData(
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        type: HKCategoryValueSleepAnalysis(rawValue: sample.value) ?? .asleepUnspecified
                    )
                }
                
                continuation.resume(returning: sleepData)
            }
            store.execute(query)
        }
    }
}
