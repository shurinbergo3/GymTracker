import Foundation
import ActivityKit

struct WorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var heartRate: Int
        var calories: Int
        var workoutType: String
        // Using a range for the timer allows the OS to handle the count-up
        var startTime: Date
    }

    // Fixed non-changing properties
    var workoutName: String
}

