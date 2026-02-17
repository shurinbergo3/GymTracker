import Foundation
import HealthKit
import SwiftUI

// MARK: - Sleep Structures

enum SleepTimeRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case sixMonths = "6 Months"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .day: return "День".localized()
        case .week: return "Неделя".localized()
        case .month: return "Месяц".localized()
        case .sixMonths: return "6 Мес.".localized()
        }
    }
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
        case .asleepDeep: return "sleep_deep".localized()
        case .asleepCore: return "sleep_core".localized()
        case .asleepREM: return "sleep_rem".localized()
        case .awake: return "sleep_awake".localized()
        case .inBed: return "sleep_in_bed".localized()
        default: return "sleep_unknown".localized()
        }
    }
}
