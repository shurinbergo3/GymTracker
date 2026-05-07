import Foundation
import HealthKit

/// Resolves the final calorie count for a finished workout.
///
/// Priority:
///  1. Trust HealthKit when it returns plausible data (≥ 2 kcal/min and the
///     workout is at least 5 minutes long). HK on a Watch always wins because
///     it has continuous HR + activity-type context we can't replicate.
///  2. Otherwise blend HR-based (Keytel) and MET-based estimates via
///     `CalorieCalculator.smartEstimate` — gives a reasonable number even
///     when the user trained iPhone-only or HR was missing.
///
/// The result is always `max(HK, smart)` so we never undercount the Watch.
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
        activityType: HKWorkoutActivityType,
        profile: Profile?
    ) -> Double {
        // Too short or no profile → trust whatever HK gave us.
        guard durationMinutes > minDurationMinutes,
              let profile,
              profile.weightKg > 0
        else { return healthKitCalories }

        // HK looks healthy → trust it.
        if healthKitCalories >= durationMinutes * suspiciousCaloriesPerMinute {
            return healthKitCalories
        }

        // HK low/zero → estimate. Smart estimator picks HR-based or MET-based.
        let estimated = CalorieCalculator.smartEstimate(
            heartRate: heartRate,
            weightKg: profile.weightKg,
            age: profile.age,
            durationMinutes: durationMinutes,
            activityType: activityType
        )

        guard estimated > 0 else { return healthKitCalories }

        return max(healthKitCalories, estimated)
    }
}
