import ActivityKit
import WidgetKit
import SwiftUI

// Shared color so widget extension doesn't need access to the app target's
// DesignSystem (Live Activity bundles must compile standalone).
private let neonGreen = Color(red: 0.34, green: 0.93, blue: 0.43)
private let restAmber = Color(red: 1.0, green: 0.71, blue: 0.21)

private extension WorkoutAttributes.ContentState {
    /// Picks the right translation for the current `languageCode` (sent from
    /// the host iOS app). Widget extension can't read the host app's
    /// .xcstrings catalog, so the few visible strings are hand-translated
    /// here for ru / en / pl.
    func t(en: String, ru: String, pl: String) -> String {
        switch languageCode {
        case "ru": return ru
        case "pl": return pl
        default: return en
        }
    }

    /// "Set 2 of 4" / "Подход 2 из 4" / "Seria 2 z 4".
    var setProgressLabel: String? {
        guard let setNumber, let totalSets, totalSets > 0 else { return nil }
        return t(
            en: "Set \(setNumber) of \(totalSets)",
            ru: "Подход \(setNumber) из \(totalSets)",
            pl: "Seria \(setNumber) z \(totalSets)"
        )
    }

    var restLabel: String { t(en: "Rest", ru: "Отдых", pl: "Odpoczynek") }
    var restLabelLower: String { t(en: "rest", ru: "отдых", pl: "odpoczynek") }
}

struct GymTrackerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutAttributes.self) { context in
            // MARK: - Lock screen / banner UI
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color(red: 0.08, green: 0.08, blue: 0.10))
                .activitySystemActionForegroundColor(neonGreen)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: Expanded
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label(
                            context.state.currentExerciseName ?? context.state.workoutType,
                            systemImage: context.state.isResting ? "timer" : "dumbbell.fill"
                        )
                        .labelStyle(.titleAndIcon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                        if let progress = context.state.setProgressLabel {
                            Text(progress)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        primaryTimer(state: context.state)
                            .font(.system(.title, design: .rounded).monospacedDigit())
                    }
                    .padding(.leading, 8)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Label("\(context.state.calories)", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.title3)
                        Label("\(context.state.heartRate)", systemImage: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                    }
                    .padding(.trailing, 8)
                }

                DynamicIslandExpandedRegion(.center) {}

                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isResting {
                        Text(context.state.restLabel)
                            .font(.caption2)
                            .foregroundStyle(restAmber)
                    }
                }

            } compactLeading: {
                primaryTimer(state: context.state)
                    .monospacedDigit()
                    .frame(maxWidth: 56)
            } compactTrailing: {
                if context.state.isResting {
                    Image(systemName: "timer")
                        .foregroundStyle(restAmber)
                        .font(.caption2)
                } else {
                    HStack(spacing: 2) {
                        Text("\(context.state.heartRate)")
                            .foregroundStyle(.white)
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption2)
                    }
                }
            } minimal: {
                Image(systemName: context.state.isResting ? "timer" : "figure.run")
                    .foregroundStyle(context.state.isResting ? restAmber : neonGreen)
            }
            .widgetURL(URL(string: "gymtracker://workout"))
            .keylineTint(context.state.isResting ? restAmber : neonGreen)
        }
    }

    /// Big timer shown in compact / expanded leading and on the lock screen.
    /// During rest — countdown to `restEndsAt` in amber.
    /// Otherwise — count-up from `startTime` in neon green.
    @ViewBuilder
    private func primaryTimer(state: WorkoutAttributes.ContentState) -> some View {
        if let restEndsAt = state.restEndsAt, restEndsAt > Date() {
            Text(timerInterval: Date()...restEndsAt, countsDown: true)
                .foregroundStyle(restAmber)
        } else {
            Text(timerInterval: state.startTime...Date.distantFuture, countsDown: false)
                .foregroundStyle(neonGreen)
        }
    }
}

// MARK: - Lock screen layout

private struct LockScreenView: View {
    let state: WorkoutAttributes.ContentState

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                // Top label — workout day / type. Always visible so user
                // recognises which session is running.
                Text(state.workoutType)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)

                // Big primary line — current exercise, or workout name fallback.
                Text(state.currentExerciseName ?? state.workoutType)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                // Set X of Y when we know it.
                if let progress = state.setProgressLabel {
                    Text(progress)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }

                // Big timer below — rest countdown OR workout total.
                if let restEndsAt = state.restEndsAt, restEndsAt > Date() {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 16))
                        Text(timerInterval: Date()...restEndsAt, countsDown: true)
                            .font(.system(.title2, design: .rounded).monospacedDigit())
                        Text(state.restLabelLower)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .foregroundStyle(restAmber)
                } else {
                    Text(timerInterval: state.startTime...Date.distantFuture, countsDown: false)
                        .font(.system(.title2, design: .rounded).monospacedDigit())
                        .foregroundStyle(neonGreen)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(state.calories) kcal")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("\(state.heartRate) BPM")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
    }
}
