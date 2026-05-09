import Foundation
import ActivityKit

struct WorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var heartRate: Int
        var calories: Int
        var workoutType: String
        // Using a range for the timer allows the OS to handle the count-up
        var startTime: Date

        // Rest / current-exercise context. All optional so old encoded states
        // (e.g. from a relaunched activity) keep decoding cleanly.
        var currentExerciseName: String?
        var setNumber: Int?
        var totalSets: Int?
        // When non-nil — rest timer is running, ends at this date.
        var restEndsAt: Date?

        // ISO 639-1 code (ru/en/pl) so the widget extension picks the same
        // language the user selected in the iPhone app, even though the
        // widget bundle has no direct access to the host app's strings.
        var languageCode: String?

        var isResting: Bool { restEndsAt != nil && (restEndsAt ?? .distantPast) > Date() }
    }

    // Fixed non-changing properties
    var workoutName: String
}
