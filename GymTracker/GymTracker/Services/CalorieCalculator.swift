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
    /// Activities and tuned to match Apple Fitness totals for the same
    /// session length. Strength training uses **session-average** MET
    /// (~3.5), not active-set MET (~5–6): rest periods dominate gym time,
    /// so a constant 5.0 over the whole session overcounts vs. Apple
    /// Fitness, which integrates the real HR curve (low between sets).
    static func metValue(for type: HKWorkoutActivityType) -> Double {
        switch type {
        case .functionalStrengthTraining,
             .traditionalStrengthTraining,
             .coreTraining:                       return 3.5
        case .crossTraining:                       return 6.0
        case .highIntensityIntervalTraining:       return 8.0
        case .mixedCardio:                         return 6.5
        case .running:                             return 9.8
        case .walking:                             return 3.5
        case .cycling:                             return 7.0
        case .rowing:                              return 7.0
        case .swimming:                            return 7.0
        case .elliptical:                          return 5.0
        case .stairs, .stairClimbing:              return 8.8
        case .jumpRope:                            return 11.0
        case .yoga, .pilates, .flexibility:        return 2.5
        case .dance:                               return 5.0
        case .boxing, .kickboxing, .martialArts:   return 8.5
        case .climbing:                            return 7.5
        default:                                   return 3.5
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

    // MARK: - iPhone-only (no Watch) — volume-based

    /// Lightweight DTO so this file stays free of SwiftData / model imports.
    struct SetSample {
        /// External resistance in kg. 0 means pure bodyweight (push-ups,
        /// pull-ups). For weighted-bodyweight (e.g. weighted dip) pass the
        /// added load and set `isBodyweightWithLoad = true`.
        let weightKg: Double
        let reps: Int
        let isBodyweightWithLoad: Bool
    }

    /// Per-set mechanical-work model used when the user has no Apple Watch.
    /// Apple Fitness on iPhone shows 0 kcal for strength training in this
    /// case (no HR signal); Body Forge can do better because it knows the
    /// actual sets the user completed.
    ///
    /// Per set: kcal ≈ (weight × g × 0.5 m × reps) / 4184 / 0.15
    ///   • 0.5 m: typical bar / joint vertical displacement per rep.
    ///   • 0.15: net muscular efficiency for resistance training (eccentric
    ///     phase + stabilizers + isometric holds make it lower than the
    ///     ~0.22 you see for cycling).
    /// Bodyweight exercises use 65% of body mass as the moved load
    /// (approximate for push-ups; pull-ups are higher, squats lower —
    /// averages out across a full session).
    ///
    /// Plus a flat 2.0 kcal/min baseline over the whole session to account
    /// for elevated metabolism between sets (EPOC) and walking around the
    /// gym. Baseline only kicks in once at least one set is completed —
    /// keeps the live counter at 0 in the simulator / before any real work.
    static func iPhoneOnlyEstimate(
        completedSets: [SetSample],
        durationMinutes: Double,
        userWeightKg: Double
    ) -> Double {
        guard durationMinutes > 0,
              userWeightKg > 0,
              !completedSets.isEmpty
        else { return 0 }

        let gravity = 9.81
        let displacementMeters = 0.5
        let joulesPerKcal = 4184.0
        let strengthEfficiency = 0.15
        let bodyweightFraction = 0.65
        let baselineKcalPerMin = 2.0

        var setsKcal: Double = 0
        for s in completedSets where s.reps > 0 {
            let resistance: Double
            if s.weightKg <= 0 {
                resistance = userWeightKg * bodyweightFraction
            } else if s.isBodyweightWithLoad {
                resistance = userWeightKg * bodyweightFraction + s.weightKg
            } else {
                resistance = s.weightKg
            }
            guard resistance > 0 else { continue }
            let joules = resistance * gravity * displacementMeters * Double(s.reps)
            setsKcal += joules / joulesPerKcal / strengthEfficiency
        }

        return setsKcal + baselineKcalPerMin * durationMinutes
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
