import Foundation
import SwiftUI

// MARK: - Progress State

enum ProgressState {
    case improved   // User lifted more weight
    case declined   // User lifted less weight
    case same       // Same performance
    case new        // First time doing this exercise
    
    var icon: String {
        switch self {
        case .improved: return "arrow.up" // Green Up
        case .declined: return "arrow.down" // Red Down
        case .same: return "arrow.forward" // White Straight
        case .new: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .improved: return DesignSystem.Colors.neonGreen
        case .declined: return .red // Explicit Red
        case .same: return .white // Explicit White
        case .new: return DesignSystem.Colors.accent
        }
    }

        var description: String {
        switch self {
        case .improved: return "Ты растёшь! Только вперёд!".localized()
        case .declined: return "Ты недостаточно усердно тренируешься".localized()
        case .same: return "Ты в режиме поддержания формы".localized()
        case .new: return "Первая тренировка".localized()
        }
    }
}

// MARK: - Exercise Progress Data

struct ExerciseProgress {
    let exerciseName: String
    let progressState: ProgressState
    let currentStats: String
    let previousStats: String?
}

// MARK: - Growth Trend System

struct GrowthTrend {
    enum Direction {
        case up     // Green: Increasing load/volume
        case flat   // White: Maintenance
        case down   // Red: Decreasing
        
        var color: Color {
            switch self {
            case .up: return DesignSystem.Colors.neonGreen
            case .flat: return .white
            case .down: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.forward"
            case .flat: return "arrow.right"
            case .down: return "arrow.down.forward"
            }
        }
        
        var description: String {
            switch self {
            case .up: return "Рост показателей".localized()
            case .flat: return "Стабильность".localized()
            case .down: return "Спад активности".localized()
            }
        }
    }
    
    let direction: Direction
    let dataPoints: [Double]
}
