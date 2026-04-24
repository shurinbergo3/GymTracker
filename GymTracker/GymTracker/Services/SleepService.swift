import Foundation
import HealthKit

/// Service for fetching and calculating sleep data.
/// Adheres to Single Responsibility Principle (SRP).
@MainActor
class SleepService {
    static let shared = SleepService()
    
    private let healthStore = HKHealthStore()
    
    // MARK: - Sleep History Helpers
    
    func fetchSleepHistory(for range: SleepTimeRange) async -> [DailySleepData] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let store = self.healthStore
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        switch range {
        case .day:
            return [] // Not used for 'day' chart
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: endDate) ?? endDate
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                guard let samples = samples as? [HKCategorySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Group by day and calculate total sleep
                var dailyTotals: [Date: TimeInterval] = [:]
                
                // Group samples by day
                let groupedSamples = Dictionary(grouping: samples) { sample in
                    calendar.startOfDay(for: sample.startDate)
                }
                
                for (day, daySamples) in groupedSamples {
                    // Filter valid sleep types
                    let sleepSamples = daySamples.filter { sample in
                        guard let type = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return false }
                        return type == .asleepCore || type == .asleepDeep || type == .asleepREM || type == .asleepUnspecified
                    }
                    
                    // Convert to basic structure for calculation
                    let data = sleepSamples.map {
                        SleepData(startDate: $0.startDate, endDate: $0.endDate, type: HKCategoryValueSleepAnalysis(rawValue: $0.value)!)
                    }.sorted { $0.startDate < $1.startDate }
                    
                    // Use the robust calculation logic
                    dailyTotals[day] = SleepService.calculateTotalDuration(from: data)
                }
                
                let result = dailyTotals.map { DailySleepData(date: $0.key, totalDuration: $0.value) }
                    .sorted { $0.date < $1.date }
                
                continuation.resume(returning: result)
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
    
    // Public helper for robust overlap logic
    nonisolated static func calculateTotalDuration(from segments: [SleepData]) -> TimeInterval {
        var totalDuration: TimeInterval = 0
        var currentInterval: (start: Date, end: Date)?
        
        for segment in segments {
            if let current = currentInterval {
                if segment.startDate < current.end {
                    if segment.endDate > current.end {
                        currentInterval?.end = segment.endDate
                    }
                } else {
                    totalDuration += current.end.timeIntervalSince(current.start)
                    currentInterval = (segment.startDate, segment.endDate)
                }
            } else {
                currentInterval = (segment.startDate, segment.endDate)
            }
        }
        
        if let current = currentInterval {
            totalDuration += current.end.timeIntervalSince(current.start)
        }
        
        return totalDuration
    }
}
