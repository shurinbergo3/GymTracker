import Foundation
import HealthKit
import Combine

class HealthManager: NSObject, ObservableObject {
    static let shared = HealthManager()
    
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    
    // Используем Any? для хранения, чтобы компилятор не ругался на типы "iOS 26.0"
    // Using Any? to store sessions/builders safely across SDK versions
    var _session: Any?
    var _builder: Any?
    
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
        
        let readTypes: Set<HKObjectType> = [energyType, hrType, workoutType, activitySummaryType]
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
        // Collect data
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
}
