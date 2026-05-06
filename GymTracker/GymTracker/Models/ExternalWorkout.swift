//
//  ExternalWorkout.swift
//  GymTracker
//
//  Apple Health workout coming from an external source (Apple Watch
//  fitness, Strava, Nike Run Club, etc.) — i.e. not saved by Body Forge
//  itself. Used in dashboard / history / calendar / AI context.
//

import Foundation
import HealthKit
import SwiftUI

struct ExternalWorkout: Identifiable, Hashable {
    let id: UUID
    let activityType: HKWorkoutActivityType
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval                 // seconds
    let totalEnergyBurnedKcal: Double?
    let totalDistanceMeters: Double?
    let sourceName: String                     // e.g. "Apple Watch", "Strava"
    let sourceBundleId: String

    var durationMinutes: Int { Int(duration / 60) }

    var displayName: String {
        ExternalWorkout.localizedName(for: activityType)
    }

    var iconName: String {
        ExternalWorkout.iconName(for: activityType)
    }

    var tint: Color {
        ExternalWorkout.tint(for: activityType)
    }

    var formattedDuration: String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 { return String(format: "%dч %dм".localized(), h, m) }
        return String(format: "%dм".localized(), m)
    }

    var formattedDistance: String? {
        guard let d = totalDistanceMeters, d > 0 else { return nil }
        if d >= 1000 {
            return String(format: "%.1f км".localized(), d / 1000)
        }
        return String(format: "%d м".localized(), Int(d))
    }
}

// MARK: - HKWorkoutActivityType → human display

extension ExternalWorkout {

    static func localizedName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking:               return "Ходьба".localized()
        case .running:               return "Бег".localized()
        case .cycling:               return "Велосипед".localized()
        case .hiking:                return "Поход".localized()
        case .yoga:                  return "Йога".localized()
        case .swimming:              return "Плавание".localized()
        case .functionalStrengthTraining,
             .traditionalStrengthTraining:
            return "Силовая".localized()
        case .highIntensityIntervalTraining: return "HIIT".localized()
        case .coreTraining:          return "Кор".localized()
        case .pilates:               return "Пилатес".localized()
        case .dance, .cardioDance:   return "Танцы".localized()
        case .rowing:                return "Гребля".localized()
        case .elliptical:            return "Эллипс".localized()
        case .stairClimbing,
             .stairs:                return "Ступени".localized()
        case .mixedCardio:           return "Кардио".localized()
        case .boxing,
             .kickboxing,
             .martialArts:           return "Бокс".localized()
        case .climbing:              return "Скалолазание".localized()
        case .crossTraining:         return "Кросс-тренинг".localized()
        case .flexibility:           return "Растяжка".localized()
        case .basketball:            return "Баскетбол".localized()
        case .soccer:                return "Футбол".localized()
        case .tennis:                return "Теннис".localized()
        case .golf:                  return "Гольф".localized()
        case .hockey:                return "Хоккей".localized()
        case .skatingSports:         return "Коньки".localized()
        case .snowSports,
             .downhillSkiing,
             .crossCountrySkiing,
             .snowboarding:          return "Лыжи / сноуборд".localized()
        case .surfingSports:         return "Сёрфинг".localized()
        case .paddleSports:          return "Гребля на доске".localized()
        case .waterFitness,
             .waterSports:           return "Аква".localized()
        case .mindAndBody:           return "Mind & Body".localized()
        case .cooldown:              return "Заминка".localized()
        case .preparationAndRecovery: return "Восстановление".localized()
        case .wheelchairWalkPace,
             .wheelchairRunPace:     return "Коляска".localized()
        default:                     return "Тренировка".localized()
        }
    }

    static func iconName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking, .wheelchairWalkPace:   return "figure.walk"
        case .running, .wheelchairRunPace:    return "figure.run"
        case .cycling:                        return "figure.outdoor.cycle"
        case .hiking:                         return "figure.hiking"
        case .yoga:                           return "figure.yoga"
        case .swimming:                       return "figure.pool.swim"
        case .functionalStrengthTraining,
             .traditionalStrengthTraining:    return "dumbbell.fill"
        case .highIntensityIntervalTraining:  return "bolt.heart.fill"
        case .coreTraining:                   return "figure.core.training"
        case .pilates:                        return "figure.pilates"
        case .dance, .cardioDance:            return "figure.dance"
        case .rowing:                         return "figure.rower"
        case .elliptical:                     return "figure.elliptical"
        case .stairClimbing, .stairs:         return "figure.stairs"
        case .mixedCardio:                    return "figure.mixed.cardio"
        case .boxing, .kickboxing,
             .martialArts:                    return "figure.boxing"
        case .climbing:                       return "figure.climbing"
        case .crossTraining:                  return "figure.cross.training"
        case .flexibility:                    return "figure.flexibility"
        case .basketball:                     return "figure.basketball"
        case .soccer:                         return "figure.soccer"
        case .tennis:                         return "figure.tennis"
        case .golf:                           return "figure.golf"
        case .hockey:                         return "figure.hockey"
        case .skatingSports:                  return "figure.skating"
        case .snowSports, .downhillSkiing,
             .crossCountrySkiing,
             .snowboarding:                   return "figure.skiing.downhill"
        case .surfingSports:                  return "figure.surfing"
        case .paddleSports:                   return "figure.outdoor.cycle"
        case .waterFitness, .waterSports:     return "figure.water.fitness"
        case .mindAndBody:                    return "figure.mind.and.body"
        case .cooldown:                       return "figure.cooldown"
        case .preparationAndRecovery:         return "figure.mind.and.body"
        default:                              return "heart.fill"
        }
    }

    /// Per-category accent so the dashboard / calendar markers are easy to
    /// scan. Strength stays on neon green so it visually rhymes with the
    /// app's own workouts; cardio is cyan-ish, mind/body is purple.
    static func tint(for type: HKWorkoutActivityType) -> Color {
        switch type {
        case .functionalStrengthTraining,
             .traditionalStrengthTraining,
             .crossTraining,
             .coreTraining:
            return Color(red: 0.75, green: 1.0, blue: 0.0)
        case .yoga, .pilates, .mindAndBody,
             .flexibility,
             .preparationAndRecovery, .cooldown:
            return Color(red: 0.6, green: 0.4, blue: 1.0)
        case .running, .walking, .hiking,
             .wheelchairWalkPace, .wheelchairRunPace:
            return Color(red: 0.45, green: 0.85, blue: 1.0)
        case .swimming, .waterFitness, .waterSports,
             .surfingSports, .paddleSports:
            return Color.cyan
        case .cycling, .elliptical, .rowing,
             .stairClimbing, .stairs,
             .highIntensityIntervalTraining,
             .mixedCardio, .cardioDance, .dance:
            return .orange
        default:
            return Color.white.opacity(0.7)
        }
    }
}
