import Foundation
import HealthKit
import Combine
import SwiftUI

class HealthManager: NSObject, ObservableObject, HealthProvider {
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
        // Optimization: Don't request if already authorized
        if isAuthorized { return true }

        guard HKHealthStore.isHealthDataAvailable() else {
            #if DEBUG
            print("HealthKit not available on this device")
            #endif
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
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!
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
            #if DEBUG
            print("HealthKit Authorization Failed: \(error.localizedDescription)")
            #endif
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
        
        #if DEBUG
        print("✅ Workout started: \(workoutType.rawValue)")
        #endif
    }
    
    func endWorkout(activityType: HKWorkoutActivityType = .functionalStrengthTraining, startDate: Date? = nil, endDate: Date? = nil) async {
        // Use provided start date/end date OR fallback to internal state (legacy/safety)
        // If coming from WorkoutManager restore, 'startDate' will be passed explicitly.
        // If internal state is lost (app killed), 'workoutStartDate' might be nil, so 'startDate' arg is critical.
        guard let finalStartDate = startDate ?? workoutStartDate else {
             #if DEBUG
             print("❌ endWorkout ignored: No start date available")
             #endif
             return 
        }
        
        // If already stopped internally, just ensure we clean up queries, but proceed with saving if we have dates
        isWorkoutActive = false
        workoutStartDate = nil
        stopLiveQueries()
        
        let finalEndDate = endDate ?? Date()
        let duration = finalEndDate.timeIntervalSince(finalStartDate)
        
        // Fetch actual metrics from HealthKit
        let calories = await fetchCaloriesForWorkout(start: finalStartDate, end: finalEndDate)
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = .indoor
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        do {
            try await builder.beginCollection(at: finalStartDate)
            
            // Add calorie data as sample BEFORE finishing
            if calories > 0 {
                guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
                    #if DEBUG
                    print("⚠️ Could not create energy type")
                    #endif
                    try await builder.endCollection(at: finalEndDate)
                    _ = try await builder.finishWorkout()
                    return
                }
                
                let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
                let energySample = HKQuantitySample(type: energyType, quantity: energyQuantity, start: finalStartDate, end: finalEndDate)
                
                try await builder.addSamples([energySample])
            }
            
            try await builder.endCollection(at: finalEndDate)
            _ = try await builder.finishWorkout()
            
            #if DEBUG
            print("✅ HKWorkout saved successfully:")
            print("   Duration: \(Int(duration))s")
            print("   Calories: \(Int(calories))kcal")
            print("   Type: \(activityType.rawValue)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to save HKWorkout: \(error.localizedDescription)")
            #endif
        }
    }
    
    func discardWorkout() async {
        isWorkoutActive = false
        workoutStartDate = nil
        stopLiveQueries()
        #if DEBUG
        print("Workout Discarded")
        #endif
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
    
    // MARK: - Sleep History Helpers (Delegated to SleepService)
    
    // Logic moved to SleepService.swift
    
    // Reusing the robust overlap logic for history too
    // Logic moved to SleepService.swift
    
    // Wrapper to match local helper signature if needed, or direct call
    // Logic moved to SleepService.swift

    private func itemValue(_ sample: HKQuantitySample, unit: HKUnit) -> Double {
        return sample.quantity.doubleValue(for: unit)
    }

    // MARK: - Health Stats Helpers (Steps / VO2 / Exercise minutes / Basal energy / Weekly workouts)

    /// Returns daily step counts for the last `days` days (oldest first), aligned to local-day boundaries.
    func fetchDailySteps(days: Int = 7) async -> [DailyHealthValue] {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return [] }
        return await fetchDailySumStatistics(type: stepType, unit: .count(), days: days)
    }

    /// Total steps for the current week (Monday-based locale aware).
    func fetchWeeklyStepsTotal() async -> Int {
        let values = await fetchDailySteps(days: 7)
        return Int(values.reduce(0) { $0 + $1.value })
    }

    /// Average VO2 Max over the last 30 days (ml/kg·min). Returns 0 if no data.
    func fetchVO2Max() async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
            guard let vo2Type = HKQuantityType.quantityType(forIdentifier: .vo2Max) else { return 0.0 }
            let endDate = Date()
            guard let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) else { return 0.0 }
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let unit = HKUnit(from: "ml/kg*min")

            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: vo2Type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                    guard let avg = result?.averageQuantity() else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    continuation.resume(returning: avg.doubleValue(for: unit))
                }
                store.execute(query)
            }
        }.value
    }

    /// Daily exercise minutes for the last `days` days (oldest first).
    func fetchDailyExerciseMinutes(days: Int = 7) async -> [DailyHealthValue] {
        guard let exType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return [] }
        return await fetchDailySumStatistics(type: exType, unit: .minute(), days: days)
    }

    /// Total exercise minutes for the last 7 days.
    func fetchWeeklyExerciseMinutesTotal() async -> Int {
        let values = await fetchDailyExerciseMinutes(days: 7)
        return Int(values.reduce(0) { $0 + $1.value })
    }

    /// Resting (basal) energy burned today in kcal.
    func fetchTodayBasalEnergy() async -> Double {
        guard let basalType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else { return 0 }
        let store = self.healthStore
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: basalType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0)
            }
            store.execute(query)
        }
    }

    /// Daily basal energy for the last `days` days.
    func fetchDailyBasalEnergy(days: Int = 7) async -> [DailyHealthValue] {
        guard let basalType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else { return [] }
        return await fetchDailySumStatistics(type: basalType, unit: .kilocalorie(), days: days)
    }

    /// HKWorkout count for the last 7 days.
    func fetchWorkoutsThisWeek() async -> Int {
        let store = self.healthStore
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                continuation.resume(returning: samples?.count ?? 0)
            }
            store.execute(query)
        }
    }

    /// Daily workout counts for the last `days` days.
    func fetchDailyWorkoutCounts(days: Int = 7) async -> [DailyHealthValue] {
        let store = self.healthStore
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date()).addingTimeInterval(86400) // tomorrow midnight
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let samples: [HKWorkout] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }

        var buckets: [Date: Int] = [:]
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            buckets[day, default: 0] += 1
        }

        var result: [DailyHealthValue] = []
        for offset in (1...days).reversed() {
            if let day = calendar.date(byAdding: .day, value: -offset + 1, to: calendar.startOfDay(for: Date())) {
                result.append(DailyHealthValue(date: day, value: Double(buckets[day] ?? 0)))
            }
        }
        return result
    }

    // MARK: - Private statistics-collection helper

    private func fetchDailySumStatistics(type: HKQuantityType, unit: HKUnit, days: Int) async -> [DailyHealthValue] {
        let store = self.healthStore
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date()).addingTimeInterval(86400) // tomorrow start
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }

        let interval = DateComponents(day: 1)
        let anchorComponents = calendar.dateComponents([.day, .month, .year], from: calendar.startOfDay(for: Date()))
        guard let anchorDate = calendar.date(from: anchorComponents) else { return [] }

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate),
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, results, _ in
                var output: [DailyHealthValue] = []
                results?.enumerateStatistics(from: startDate, to: endDate) { stat, _ in
                    let value = stat.sumQuantity()?.doubleValue(for: unit) ?? 0
                    output.append(DailyHealthValue(date: stat.startDate, value: value))
                }
                continuation.resume(returning: output)
            }
            store.execute(query)
        }
    }
}

// MARK: - Daily value model
struct DailyHealthValue: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Sleep Structures

// Sleep types moved to GymTracker/Models/SleepModels.swift

