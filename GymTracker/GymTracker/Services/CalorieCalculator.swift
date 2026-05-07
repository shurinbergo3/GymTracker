import Foundation
import HealthKit

/// Pure logic service for calculating calories.
/// Two estimation paths:
///  • HR-based (Keytel formula) — most accurate when an Apple Watch is feeding
///    live heart-rate samples.
///  • MET-based (Compendium of Physical Activities) — used when there's no HR
///    available (no Watch, sensor disconnect, iPhone-only). Without this
///    fallback the Live Activity bar would sit at 0 kcal for the whole gym
///    session, which is what users feel as "calories don't match Apple Fitness".
struct CalorieCalculator {

    // MARK: - HR-based (Keytel)

    /// Calories burned per minute estimated from heart rate.
    /// Formula: Calories/min = (-55.0969 + (0.6309 x HR) + (0.1988 x Weight) + (0.2017 x Age)) / 4.184
    /// Notes: validated for HR 90+ bpm; below that we assume sub-aerobic effort
    /// and prefer the MET fallback to avoid negative-calorie artefacts.
    static func calculate(
        heartRate: Double,
        weightKg: Double,
        age: Double,
        durationMinutes: Double
    ) -> Double {
        guard heartRate > 0, weightKg > 0, durationMinutes > 0 else { return 0 }

        let caloriesPerMin = (-55.0969 + (0.6309 * heartRate) + (0.1988 * weightKg) + (0.2017 * age)) / 4.184

        if caloriesPerMin > 0 {
            return caloriesPerMin * durationMinutes
        }

        return 0
    }

    // MARK: - MET-based (no HR required)

    /// MET → kcal/min/kg, derived from the 2011 Compendium of Physical
    /// Activities. Picked to roughly match what Apple Fitness shows for a
    /// 75-kg lifter with no Watch data — strength training is intentionally
    /// modest (5.0) because rest periods dominate set time.
    static func metValue(for type: HKWorkoutActivityType) -> Double {
        switch type {
        case .functionalStrengthTraining,
             .traditionalStrengthTraining,
             .coreTraining:                       return 5.0
        case .crossTraining:                       return 7.0
        case .highIntensityIntervalTraining:       return 8.0
        case .mixedCardio:                         return 7.0
        case .running:                             return 9.8
        case .walking:                             return 3.5
        case .cycling:                             return 7.5
        case .rowing:                              return 7.0
        case .swimming:                            return 7.5
        case .elliptical:                          return 5.5
        case .stairs, .stairClimbing:              return 8.8
        case .jumpRope:                            return 11.0
        case .yoga, .pilates, .flexibility:        return 2.8
        case .dance:                               return 5.5
        case .boxing, .kickboxing, .martialArts:   return 9.0
        case .climbing:                            return 8.0
        default:                                   return 5.0
        }
    }

    /// MET-based calorie estimate, no HR needed.
    /// kcal = MET × weightKg × hours.
    static func metBased(
        activityType: HKWorkoutActivityType,
        weightKg: Double,
        durationMinutes: Double
    ) -> Double {
        guard weightKg > 0, durationMinutes > 0 else { return 0 }
        let met = metValue(for: activityType)
        return met * weightKg * (durationMinutes / 60.0)
    }

    // MARK: - Smart selector

    /// Returns the best calorie estimate available for the live workout.
    ///
    /// Priority:
    ///  1. HR-based (Keytel) — when HR ≥ 90 bpm. This is what Apple Fitness
    ///     uses on Watch internally for HR-driven workouts.
    ///  2. MET-based — when HR is missing or below the Keytel-validated band.
    ///
    /// Rationale: the Keytel formula goes negative for HR ~70 bpm at typical
    /// weights/ages, which produced 0 kcal during long rest periods between
    /// sets. Falling back to MET keeps the bar moving smoothly.
    static func smartEstimate(
        heartRate: Double,
        weightKg: Double,
        age: Double,
        durationMinutes: Double,
        activityType: HKWorkoutActivityType
    ) -> Double {
        let hrEstimate = calculate(
            heartRate: heartRate,
            weightKg: weightKg,
            age: age,
            durationMinutes: durationMinutes
        )

        let metEstimate = metBased(
            activityType: activityType,
            weightKg: weightKg,
            durationMinutes: durationMinutes
        )

        // Trust the HR formula only when HR is in its validated range
        // (>= 90 bpm) AND it gives something at least as plausible as MET.
        if heartRate >= 90 && hrEstimate > 0 {
            return max(hrEstimate, metEstimate * 0.7)  // never undercount badly
        }

        return metEstimate
    }
}
