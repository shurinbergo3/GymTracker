import Foundation
import HealthKit
import Combine
import SwiftUI

class HealthManager: NSObject, ObservableObject {
    static let shared = HealthManager()
    
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    
    // Tracking State
    private var isWorkoutActive = false
    private var workoutStartDate: Date?
    private var heartRateQuery: HKQuery?
    private var calorieQuery: HKQuery?
    
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
    
    // MARK: - Workout Management (Robust/Legacy Compatible)
    
    func startWorkout(workoutType: HKWorkoutActivityType) async {
        guard isAuthorized else { return }
        
        isWorkoutActive = true
        workoutStartDate = Date()
        
        // Start Live Queries
        startLiveQueries()
        
        print("Workout Started locally (HealthKit queries active)")
    }
    
    func endWorkout() async {
        guard isWorkoutActive, let startDate = workoutStartDate else { return }
        
        let endDate = Date()
        isWorkoutActive = false
        workoutStartDate = nil
        
        stopLiveQueries()
        
        // Save Workout to HealthKit Manually using HKWorkoutBuilder
        let duration = endDate.timeIntervalSince(startDate)
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        do {
            try await builder.beginCollection(at: startDate)
            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()
            print("Usage: Manual HKWorkout saved via Builder: \(duration)s")
        } catch {
            print("Failed to save manual HKWorkout: \(error)")
        }
    }
    
    func discardWorkout() async {
        isWorkoutActive = false
        workoutStartDate = nil
        stopLiveQueries()
        print("Workout Discarded")
    }
    
    // MARK: - Live Queries (HKAnchoredObjectQuery)
    
    private func startLiveQueries() {
        // Heart Rate query
        if let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
            
            let query = HKAnchoredObjectQuery(type: hrType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
                self?.processSamples(samples, type: hrType)
            }
            
            query.updateHandler = { [weak self] _, samples, _, _, _ in
                self?.processSamples(samples, type: hrType)
            }
            
            healthStore.execute(query)
            heartRateQuery = query
        }
        
        // Active Energy query
        if let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
             let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
            
            let query = HKAnchoredObjectQuery(type: calType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
                self?.processSamples(samples, type: calType)
            }
            
            query.updateHandler = { [weak self] _, samples, _, _, _ in
                self?.processSamples(samples, type: calType)
            }
            
            healthStore.execute(query)
            calorieQuery = query
        }
    }
    
    private func stopLiveQueries() {
        if let query = heartRateQuery { healthStore.stop(query) }
        if let query = calorieQuery { healthStore.stop(query) }
        heartRateQuery = nil
        calorieQuery = nil
    }
    
    private func processSamples(_ samples: [HKSample]?, type: HKQuantityType) {
        guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else { return }
        
        DispatchQueue.main.async {
            if type.identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
                if let lastSample = samples.last {
                    let hr = self.itemValue(lastSample, unit: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    self.onHeartRateUpdate?(Int(hr))
                }
            } else if type.identifier == HKQuantityTypeIdentifier.activeEnergyBurned.rawValue {
                // Re-fetch total sum from workoutStartDate to enable cumulative total
                self.triggerTotalFetch()
            }
        }
    }
    
    private func triggerTotalFetch() {
        guard let startDate = workoutStartDate else { return }
        Task {
            let total = await fetchCaloriesForWorkout(start: startDate, end: Date())
            await MainActor.run {
                self.onCalorieUpdate?(Int(total))
            }
        }
    }
    
    // MARK: - Data Fetching helpers
    
    func fetchCaloriesForWorkout(start: Date, end: Date) async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
            guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0.0 }
            
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            
            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                    guard let result = result, let sum = result.sumQuantity() else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    continuation.resume(returning: sum.doubleValue(for: HKUnit.kilocalorie()))
                }
                store.execute(query)
            }
        }.value
    }
    
    func fetchLatestHeartRate(since start: Date? = nil) async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
             guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return 0.0 }
            let startDate = start ?? Date().addingTimeInterval(-3600)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    guard let sample = samples?.first as? HKQuantitySample, error == nil else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    continuation.resume(returning: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                }
                store.execute(query)
            }
        }.value
    }
    
    func fetchAverageHeartRate(start: Date, end: Date) async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
            guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return 0.0 }
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            
            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, error in
                    guard let result = result, let averageQuantity = result.averageQuantity() else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    continuation.resume(returning: averageQuantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                }
                store.execute(query)
            }
        }.value
    }
    
    func fetchRestingHeartRate() async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
            guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return 0.0 }
            
            // Fetch average resting HR for the last 7 days
            let endDate = Date()
            guard let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) else { return 0.0 }
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            
            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: restingHRType,
                    quantitySamplePredicate: predicate,
                    options: .discreteAverage
                ) { _, result, error in
                    guard let result = result,
                          let averageQuantity = result.averageQuantity(),
                          error == nil else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    let avgHR = averageQuantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    continuation.resume(returning: avgHR)
                }
                store.execute(query)
            }
        }.value
    }
    
    
    // MARK: - Legacy Helpers
    func fetchTodaySteps() async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let store = self.healthStore
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                continuation.resume(returning: Int(result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0))
            }
            store.execute(query)
        }
    }
    
    func fetchTodayDistance() async -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return 0 }
        let store = self.healthStore
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: HKUnit.meterUnit(with: .kilo)) ?? 0)
            }
            store.execute(query)
        }
    }
    
    func fetchActivitySummary() async -> HKActivitySummary? {
         let store = self.healthStore
         let calendar = Calendar.current
         var dateComponents = calendar.dateComponents([.day, .month, .year, .era], from: Date())
         dateComponents.calendar = calendar
         let predicate = HKQuery.predicateForActivitySummary(with: dateComponents)
         
         return await withCheckedContinuation { continuation in
             let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, _ in
                 continuation.resume(returning: summaries?.first)
             }
             store.execute(query)
         }
    }
    
    func fetchSleepData() async -> [SleepData] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let store = self.healthStore
        
        // Fetch data for the last 24 hours
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: endDate) else { return [] }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard let samples = samples as? [HKCategorySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                
                let sleepData = samples.compactMap { sample -> SleepData? in
                    guard let type = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return nil }
                    return SleepData(startDate: sample.startDate, endDate: sample.endDate, type: type)
                }
                continuation.resume(returning: sleepData)
            }
            store.execute(query)
        }
    }
    
    private func itemValue(_ sample: HKQuantitySample, unit: HKUnit) -> Double {
        return sample.quantity.doubleValue(for: unit)
    }
}

