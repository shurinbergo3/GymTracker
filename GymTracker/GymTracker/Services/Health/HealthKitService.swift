//
//  HealthKitService.swift
//  GymTracker
//
//  HealthKit implementation of HealthService
//

import Foundation
import HealthKit
import Combine

/// HealthKit implementation
/// Single Responsibility: Handle HealthKit operations only
final class HealthKitService: NSObject, HealthService {
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    var isWorkoutActive = false
    
    private var workoutStartDate: Date?
    private var heartRateQuery: HKQuery?
    private var calorieQuery: HKQuery?
    
    var onHeartRateUpdate: ((Int) -> Void)?
    var onCalorieUpdate: ((Int) -> Void)?
    
    // MARK: - HealthService Protocol
    
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        
        let types = createHealthKitTypes()
        
        do {
            try await requestHealthKitAuth(types: types)
            isAuthorized = true
            return true
        } catch {
            return false
        }
    }
    
    func startWorkout(workoutType: HKWorkoutActivityType) async {
        guard isAuthorized else { return }
        
        isWorkoutActive = true
        workoutStartDate = Date()
        startLiveQueries()
    }
    
    func endWorkout(
        activityType: HKWorkoutActivityType,
        startDate: Date?,
        endDate: Date?
    ) async {
        stopLiveQueries()
        
        let finalStart = startDate ?? workoutStartDate ?? Date()
        let finalEnd = endDate ?? Date()
        let duration = finalEnd.timeIntervalSince(finalStart)
        let calories = await fetchCaloriesForWorkout(start: finalStart, end: finalEnd)
        
        await saveWorkoutToHealthKit(
            activityType: activityType,
            start: finalStart,
            end: finalEnd,
            duration: duration,
            calories: calories
        )
        
        resetWorkoutState()
    }
    
    func discardWorkout() async {
        stopLiveQueries()
        resetWorkoutState()
    }
    
    func fetchLatestHeartRate(since start: Date?) async -> Double {
        await fetchHRValue(since: start)
    }
    
    func fetchCaloriesForWorkout(start: Date, end: Date) async -> Double {
        await fetchCalorieValue(start: start, end: end)
    }
    
    // MARK: - Private Helpers (<10 lines)
    
    private func createHealthKitTypes() -> (read: Set<HKSampleType>, write: Set<HKSampleType>) {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let workoutType = HKObjectType.workoutType()
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let read: Set<HKSampleType> = [energyType, heartRateType, workoutType]
        let write: Set<HKSampleType> = [energyType, workoutType]
        
        return (read, write)
    }
    
    private func requestHealthKitAuth(types: (read: Set<HKSampleType>, write: Set<HKSampleType>)) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: types.write, read: types.read) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func startLiveQueries() {
        startHeartRateQuery()
        startCalorieQuery()
    }
    
    private func stopLiveQueries() {
        if let query = heartRateQuery { healthStore.stop(query) }
        if let query = calorieQuery { healthStore.stop(query) }
        heartRateQuery = nil
        calorieQuery = nil
    }
    
    private func resetWorkoutState() {
        isWorkoutActive = false
        workoutStartDate = nil
    }
    
    private func startHeartRateQuery() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }
        
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    private func startCalorieQuery() {
        guard let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        let query = HKAnchoredObjectQuery(
            type: calType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processCalorieSamples(samples)
        }
        
        healthStore.execute(query)
        calorieQuery = query
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], let latest = samples.last else { return }
        
        let hr = Int(latest.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
        onHeartRateUpdate?(hr)
    }
    
    private func processCalorieSamples(_ samples: [HKSample]?) {
        guard let start = workoutStartDate else { return }
        
        Task {
            let total = await fetchCaloriesForWorkout(start: start, end: Date())
            onCalorieUpdate?(Int(total))
        }
    }
    
    private func fetchHRValue(since start: Date?) async -> Double {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return 0
        }
        
        let predicate = createPredicate(since: start)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: hrType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0)
                    return
                }
                let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchCalorieValue(start: Date, end: Date) async -> Double {
        guard let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: calType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: .kilocalorie()))
            }
            healthStore.execute(query)
        }
    }
    
    private func createPredicate(since start: Date?) -> NSPredicate? {
        guard let start = start else { return nil }
        return HKQuery.predicateForSamples(withStart: start, end: nil, options: .strictStartDate)
    }
    
    private func saveWorkoutToHealthKit(
        activityType: HKWorkoutActivityType,
        start: Date,
        end: Date,
        duration: TimeInterval,
        calories: Double
    ) async {
        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        config.locationType = .indoor
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: config, device: .local())
        
        do {
            try await builder.beginCollection(at: start)
            
            if calories > 0 {
                let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
                let calorieSample = HKQuantitySample(
                    type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                    quantity: calorieQuantity,
                    start: start,
                    end: end
                )
                try await builder.addSamples([calorieSample])
            }
            
            try await builder.endCollection(at: end)
            try await builder.finishWorkout()
        } catch {
            #if DEBUG
            print("❌ Failed to save HKWorkout: \(error)")
            #endif
        }
    }
}
