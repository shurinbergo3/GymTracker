import Foundation

/// Pure logic service for calculating calories.
/// Adheres to Single Responsibility Principle (SRP).
struct CalorieCalculator {
    
    /// Calculates estimated calories burned based on metabolic formula.
    /// Formula: Calories/min = (-55.0969 + (0.6309 x HR) + (0.1988 x Weight) + (0.2017 x Age)) / 4.184
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
}
