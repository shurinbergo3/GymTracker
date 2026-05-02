import Foundation

/// Resolves the final calorie count for a finished workout.
/// Trusts HealthKit when it returns substantial data; otherwise applies the
/// HR-based metabolic estimate as a fallback (covers cases where the user
/// didn't wear the Watch or HK undercounted).
struct WorkoutCaloriesResolver {

    struct Profile {
        let weightKg: Double
        let age: Double
    }

    /// Below this many calories-per-minute HK is treated as suspiciously low.
    /// Workouts shorter than `minDurationMinutes` skip the fallback —
    /// too short to estimate reliably.
    private static let minDurationMinutes: Double = 5
    private static let suspiciousCaloriesPerMinute: Double = 2

    static func resolve(
        healthKitCalories: Double,
        heartRate: Double,
        durationMinutes: Double,
        profile: Profile?
    ) -> Double {
        guard durationMinutes > minDurationMinutes,
              healthKitCalories < durationMinutes * suspiciousCaloriesPerMinute,
              let profile,
              heartRate > 0,
              profile.weightKg > 0
        else {
            return healthKitCalories
        }

        let estimated = CalorieCalculator.calculate(
            heartRate: heartRate,
            weightKg: profile.weightKg,
            age: profile.age,
            durationMinutes: durationMinutes
        )

        guard estimated > 0 else { return healthKitCalories }

        return max(healthKitCalories, estimated)
    }
}
