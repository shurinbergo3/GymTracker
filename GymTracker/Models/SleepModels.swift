import Foundation
import HealthKit
import SwiftUI

// MARK: - Sleep Structures

enum SleepTimeRange: String, CaseIterable, Identifiable {
    case day = "День"
    case week = "Неделя"
    case month = "Месяц"
    case sixMonths = "6 Мес."
    
    var id: String { rawValue }
}

struct DailySleepData: Identifiable {
    let id = UUID()
    let date: Date
    let totalDuration: TimeInterval
}

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
        case .asleepDeep: return .purple
        case .asleepCore: return .blue
        case .asleepREM: return .cyan
        case .awake: return .orange
        case .inBed: return .gray.opacity(0.3)
        default: return .clear
        }
    }
    
    var label: String {
        switch type {
        case .asleepDeep: return String(localized: "sleep_deep")
        case .asleepCore: return String(localized: "sleep_core")
        case .asleepREM: return String(localized: "sleep_rem")
        case .awake: return String(localized: "sleep_awake")
        case .inBed: return String(localized: "sleep_in_bed")
        default: return String(localized: "sleep_unknown")
        }
    }
}
