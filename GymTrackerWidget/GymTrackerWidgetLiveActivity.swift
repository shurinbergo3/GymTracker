import ActivityKit
import WidgetKit
import SwiftUI



struct GymTrackerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutAttributes.self) { context in
            // Lock screen/banner UI
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text(context.state.workoutType)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(timerInterval: context.state.startTime...Date().addingTimeInterval(3600*3), countsDown: false)
                        .font(.system(.title2, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(context.state.calories) kcal")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text("\(context.state.heartRate) BPM")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color(red: 0.1, green: 0.1, blue: 0.12)) // Dark background
            .activitySystemActionForegroundColor(Color.green)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Label(context.state.workoutType, systemImage: "dumbbell.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(timerInterval: context.state.startTime...Date().addingTimeInterval(3600*3), countsDown: false)
                            .font(.system(.title, design: .rounded).monospacedDigit())
                            .foregroundStyle(.green)
                    }
                    .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Label("\(context.state.calories)", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.title3)
                        Label("\(context.state.heartRate)", systemImage: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                    }
                    .padding(.trailing, 8)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    // Start/End time or simple text
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Optional bottom region
                }
                
            } compactLeading: {
                Text(timerInterval: context.state.startTime...Date().addingTimeInterval(3600*3), countsDown: false)
                    .monospacedDigit()
                    .foregroundStyle(.green)
                    .frame(maxWidth: 40)
            } compactTrailing: {
                HStack(spacing: 2) {
                    Text("\(context.state.heartRate)")
                        .foregroundStyle(.white)
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.caption2)
                }
            } minimal: {
                Image(systemName: "figure.run")
                    .foregroundStyle(.green)
            }
            .widgetURL(URL(string: "gymtracker://workout"))
            .keylineTint(Color.green)
        }
    }
}
