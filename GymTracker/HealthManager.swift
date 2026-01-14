import Foundation
import HealthKit

import Combine

class HealthManager: ObservableObject {
    static let shared = HealthManager()
    
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            return false
        }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType()
        ]
        
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run {
                self.isAuthorized = true
            }
            return true
        } catch {
            print("HealthKit Authorization Failed: \(error.localizedDescription)")
            return false
        }
    }
    
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
