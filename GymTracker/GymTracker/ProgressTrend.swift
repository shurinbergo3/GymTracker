//
//  ProgressTrend.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import Foundation

// MARK: - Progress Trend Analysis

enum ProgressTrend {
    case surge      // >10% increase: Strong growth
    case growth     // 2-10% increase: Steady progress
    case maintenance // ±2%: Holding form
    case decline    // -10 to -25%: Decreasing tone
    case loss       // <-25% or 4+ weeks inactive: Critical drop
    
    // MARK: - UI Properties
    
    var icon: String {
        switch self {
        case .surge: return "arrow.up"
        case .growth: return "arrow.up.forward"
        case .maintenance: return "arrow.forward"
        case .decline: return "arrow.down.forward"
        case .loss: return "arrow.down"
        }
    }
    
    var rotation: Double {
        switch self {
        case .surge: return 0         // Straight up
        case .growth: return -45      // Up-right diagonal
        case .maintenance: return 0   // Straight right
        case .decline: return 45      // Down-right diagonal
        case .loss: return 0          // Straight down
        }
    }
    
    var color: Color {
        switch self {
        case .surge: return DesignSystem.Colors.neonGreen
        case .growth: return Color.green.opacity(0.7)
        case .maintenance: return Color.white.opacity(0.6)
        case .decline: return Color.orange
        case .loss: return Color.red
        }
    }
    
    var title: String {
        switch self {
        case .surge: return "Мощный рост!".localized()
        case .growth: return "Стабильный прогресс".localized()
        case .maintenance: return "Удержание формы".localized()
        case .decline: return "Снижение тонуса".localized()
        case .loss: return "Критический спад".localized()
        }
    }
    
    var subtitle: String {
        switch self {
        case .surge: return "Вы превосходите себя".localized()
        case .growth: return "Веса или повторения растут".localized()
        case .maintenance: return "Для роста повысьте нагрузку".localized()
        case .decline: return "Пора возвращаться в ритм".localized()
        case .loss: return "Начните с восстановления".localized()
        }
    }
    
    // MARK: - Calculation Logic
    
    /// Calculates progress trend based on Volume Load analysis
    /// Volume Load = sum(weight × reps × sets) over time periods
    static func calculate(from sessions: [WorkoutSession]) -> ProgressTrend {
        let now = Date()
        let calendar = Calendar.current
        
        // Helper: Get date 'weeks' ago from now
        func dateWeeksAgo(_ weeks: Int) -> Date {
            calendar.date(byAdding: .weekOfYear, value: -weeks, to: now) ?? now
        }
        
        // Helper: Calculate total volume for sessions in date range
        func volumeInRange(from: Date, to: Date) -> Double {
            let filteredSessions = sessions.filter { session in
                session.date >= from && session.date < to && session.isCompleted
            }
            
            return filteredSessions.reduce(0.0) { total, session in
                let sessionVolume = session.sets.reduce(0.0) { setTotal, set in
                    setTotal + (set.weight * Double(set.reps))
                }
                return total + sessionVolume
            }
        }
        
        // 1. Current Week Volume (last 7 days)
        let currentWeekStart = dateWeeksAgo(1)
        let currentVolume = volumeInRange(from: currentWeekStart, to: now)
        
        // 2. Baseline Volume (average of previous 3 weeks: weeks 2-4)
        let week2Start = dateWeeksAgo(2)
        let week3Start = dateWeeksAgo(3)
        let week4Start = dateWeeksAgo(4)
        
        let week2Volume = volumeInRange(from: week2Start, to: currentWeekStart)
        let week3Volume = volumeInRange(from: week3Start, to: week2Start)
        let week4Volume = volumeInRange(from: week4Start, to: week3Start)
        
        let baselineVolume = (week2Volume + week3Volume + week4Volume) / 3.0
        
        // 3. Special case: New user (no baseline)
        if baselineVolume == 0 {
            return currentVolume > 0 ? .surge : .maintenance
        }
        
        // 4. Check for inactivity FIRST (priority over volume calculation)
        // Get most recent workout date
        let completedSessions = sessions.filter { $0.isCompleted }.sorted { $0.date > $1.date }
        
        if let lastWorkout = completedSessions.first?.date {
            let daysSinceLastWorkout = calendar.dateComponents([.day], from: lastWorkout, to: now).day ?? 0
            
            // 50+ days inactive → Critical loss (red arrow down)
            if daysSinceLastWorkout >= 50 {
                return .loss
            }
            
            // 21+ days (3 weeks) inactive → Maintenance (white arrow, motivate to resume)
            if daysSinceLastWorkout >= 21 {
                return .maintenance
            }
        } else {
            // No workouts ever → maintenance (neutral state for new users)
            return .maintenance
        }
        
        // 5. Calculate percentage change (only if user is active)
        let percentageChange = ((currentVolume - baselineVolume) / baselineVolume) * 100
        
        // 6. Determine trend based on thresholds
        switch percentageChange {
        case 10...:
            return .surge
        case 2..<10:
            return .growth
        case -2..<2:
            return .maintenance
        case -25..<(-10):
            return .decline
        default: // < -25%
            return .loss
        }
    }
}
