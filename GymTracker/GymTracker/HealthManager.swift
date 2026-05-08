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

    // Long-lived observer for external HK workouts (Apple Watch / 3rd-party apps).
    // Set up once after authorization; fires `.healthKitWorkoutsDidChange` so the
    // dashboard refreshes when new workouts arrive without requiring a tab switch.
    private var externalWorkoutsObserver: HKObserverQuery?

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
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
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
            startObservingExternalWorkouts()
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


    // MARK: - Recovery: HRV (SDNN, ms)

    /// Average heart-rate variability (SDNN) over the last `days` days, in ms.
    /// Returns 0 when no samples exist (typical for users without an Apple Watch).
    func fetchAverageHRV(days: Int = 7) async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
            guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return 0.0 }
            let endDate = Date()
            guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else { return 0.0 }
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let unit = HKUnit.secondUnit(with: .milli)

            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
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

    // MARK: - Body metrics (height / weight) — for BMI

    /// Most recent height sample, in centimetres. Returns 0 if absent.
    func fetchLatestHeightCm() async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
            guard let type = HKQuantityType.quantityType(forIdentifier: .height) else { return 0.0 }
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                    guard let sample = samples?.first as? HKQuantitySample else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    continuation.resume(returning: sample.quantity.doubleValue(for: .meterUnit(with: .centi)))
                }
                store.execute(query)
            }
        }.value
    }

    /// Most recent body-mass sample, in kilograms. Returns 0 if absent.
    func fetchLatestBodyMassKg() async -> Double {
        let store = self.healthStore
        return await Task.detached(priority: .userInitiated) {
            guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return 0.0 }
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                    guard let sample = samples?.first as? HKQuantitySample else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    continuation.resume(returning: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)))
                }
                store.execute(query)
            }
        }.value
    }


    // MARK: - External (Apple Health) workouts

    /// Fetch HKWorkouts in the given date window that did NOT originate
    /// from Body Forge itself. These are workouts the user logged in Apple
    /// Fitness, Apple Watch, Strava, Nike Run Club, etc. — used to feed
    /// dashboard / history / calendar / AI context so the user gets a
    /// holistic picture of their training load.
    func fetchExternalWorkouts(from start: Date, to end: Date) async -> [ExternalWorkout] {
        guard isAuthorized else { return [] }
        let store = self.healthStore
        let ownBundleId = Bundle.main.bundleIdentifier ?? ""
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let samples: [HKWorkout] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }

        return samples.compactMap { sample in
            // Skip workouts authored by this app — those are already in
            // the app's own SwiftData history and would double-count.
            let bundle: String = sample.sourceRevision.source.bundleIdentifier
            if !ownBundleId.isEmpty, bundle == ownBundleId { return nil }
            // Defensive: HK can sometimes return zero-duration phantoms
            // imported from older devices.
            guard sample.duration > 0 else { return nil }

            let calories: Double?
            if #available(iOS 16.0, *) {
                calories = sample.statistics(for: HKQuantityType(.activeEnergyBurned))?
                    .sumQuantity()?.doubleValue(for: .kilocalorie())
            } else {
                calories = sample.totalEnergyBurned?.doubleValue(for: .kilocalorie())
            }

            let distance: Double?
            if #available(iOS 16.0, *) {
                distance = sample.statistics(for: HKQuantityType(.distanceWalkingRunning))?
                    .sumQuantity()?.doubleValue(for: .meter())
                    ?? sample.statistics(for: HKQuantityType(.distanceCycling))?
                    .sumQuantity()?.doubleValue(for: .meter())
            } else {
                distance = sample.totalDistance?.doubleValue(for: .meter())
            }

            return ExternalWorkout(
                id: sample.uuid,
                activityType: sample.workoutActivityType,
                startDate: sample.startDate,
                endDate: sample.endDate,
                duration: sample.duration,
                totalEnergyBurnedKcal: calories,
                totalDistanceMeters: distance,
                sourceName: sample.sourceRevision.source.name,
                sourceBundleId: bundle
            )
        }
    }

    /// Convenience: external workouts in the last 7 days (rolling window),
    /// most recent first.
    func fetchExternalWorkoutsThisWeek() async -> [ExternalWorkout] {
        let end = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -7, to: end) else { return [] }
        return await fetchExternalWorkouts(from: start, to: end)
    }

    /// Convenience: external workouts on a specific calendar day.
    func fetchExternalWorkouts(on day: Date) async -> [ExternalWorkout] {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: day)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        return await fetchExternalWorkouts(from: dayStart, to: dayEnd)
    }

    // MARK: - External workouts live observer

    /// Starts a long-lived `HKObserverQuery` on the workout type so the UI is
    /// notified whenever new workouts are added by Apple Watch or third-party
    /// apps. Without this, the dashboard's streak card sees stale data because
    /// the iPhone–Watch sync can lag behind app launch by 30+ seconds, and the
    /// view's `.task` runs only on appear. Idempotent: re-calling is a no-op.
    func startObservingExternalWorkouts() {
        guard isAuthorized, externalWorkoutsObserver == nil else { return }

        let workoutType = HKObjectType.workoutType()
        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { _, completionHandler, error in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .healthKitWorkoutsDidChange, object: nil)
                }
            }
            completionHandler()
        }
        healthStore.execute(query)
        externalWorkoutsObserver = query

        // Background delivery so the observer also fires when the app is
        // suspended — newly synced Watch workouts appear immediately on next
        // foreground without an extra fetch latency.
        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { _, _ in }
    }

    // MARK: - Private statistics-collection helper

    private func fetchDailySumStatistics(type: HKQuantityType, unit: HKUnit, days: Int) async -> [DailyHealthValue] {
        let store = self.healthStore
        let calendar = Calendar.current
        // End the window at "now" so HKStatisticsCollectionQuery doesn't
        // emit an empty bucket for tomorrow (which would dilute averages and
        // make `.last` return zero for "today").
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: startOfToday) else { return [] }

        let interval = DateComponents(day: 1)
        let anchorDate = startOfToday

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate),
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, results, _ in
                var output: [DailyHealthValue] = []
                results?.enumerateStatistics(from: startDate, to: now) { stat, _ in
                    let value = stat.sumQuantity()?.doubleValue(for: unit) ?? 0
                    output.append(DailyHealthValue(date: stat.startDate, value: value))
                }
                // Defensive: chronological order, drop any future buckets.
                output.sort { $0.date < $1.date }
                output = output.filter { $0.date <= startOfToday }
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

// MARK: - Notifications

extension Notification.Name {
    /// Posted whenever HealthKit reports new/changed workout samples. Listeners
    /// (e.g. DashboardView) re-fetch their external-workout slices on receipt.
    static let healthKitWorkoutsDidChange = Notification.Name("healthKitWorkoutsDidChange")
}

