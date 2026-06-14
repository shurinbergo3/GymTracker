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

// MARK: - Shared building blocks

/// Brand logo rendered as a small rounded chip. Used in the Dynamic Island,
/// the compact pill and on the lock screen so the activity always reads as
/// "this is the gym app".
@ViewBuilder
private func brandLogo(size: CGFloat) -> some View {
    Image("BrandLogo")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        )
}

/// Linear bar that depletes over the full rest window. Self-updating via the
/// system `timerInterval` progress — no per-second pushes needed. Renders
/// nothing for states without a known rest window (e.g. legacy encoded states).
@ViewBuilder
private func restProgressBar(state: WorkoutAttributes.ContentState) -> some View {
    if let start = state.restStartedAt, let end = state.restEndsAt, end > start {
        ProgressView(timerInterval: start...end, countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .tint(restAmber)
    }
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
                // MARK: Expanded — branded header + metrics, big timer below.
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        brandLogo(size: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.currentExerciseName ?? context.state.workoutType)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            if let progress = context.state.setProgressLabel {
                                Text(progress)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .lineLimit(1)
                            } else {
                                Text(context.state.workoutType)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.55))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        metricPill(icon: "flame.fill", value: "\(context.state.calories)", tint: .orange)
                        metricPill(icon: "heart.fill", value: "\(context.state.heartRate)", tint: .red)
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isResting {
                        VStack(spacing: 6) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Image(systemName: "timer")
                                    .font(.title3)
                                primaryTimer(state: context.state)
                                    .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                                Text(context.state.restLabelLower)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.55))
                            }

                            restProgressBar(state: context.state)

                            // Total workout time stays visible during rest.
                            HStack(spacing: 4) {
                                Image(systemName: "dumbbell.fill")
                                Text(timerInterval: context.state.startTime...Date.distantFuture, countsDown: false)
                                    .monospacedDigit()
                            }
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 2)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "stopwatch")
                                .font(.title3)
                                .foregroundStyle(neonGreen)
                            primaryTimer(state: context.state)
                                .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                        }
                        .padding(.top, 2)
                    }
                }

            } compactLeading: {
                HStack(spacing: 4) {
                    brandLogo(size: 16)
                    primaryTimer(state: context.state)
                        .monospacedDigit()
                        .frame(maxWidth: 44)
                }
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

    /// Compact metric chip — icon + value, used in the expanded trailing region.
    private func metricPill(icon: String, value: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(value)
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .font(.callout.weight(.medium))
    }
}

// MARK: - Lock screen layout

private struct LockScreenView: View {
    let state: WorkoutAttributes.ContentState

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                brandLogo(size: 40)

                VStack(alignment: .leading, spacing: 3) {
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
                        .lineLimit(1)

                    // Set X of Y when we know it.
                    if let progress = state.setProgressLabel {
                        Text(progress)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
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

            // Timer row — rest countdown + progress, or workout count-up.
            if let restEndsAt = state.restEndsAt, restEndsAt > Date() {
                VStack(spacing: 5) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 15))
                        Text(timerInterval: Date()...restEndsAt, countsDown: true)
                            .font(.system(.title3, design: .rounded).monospacedDigit())
                        Text(state.restLabelLower)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))

                        Spacer()

                        // Total workout time stays visible during rest.
                        HStack(spacing: 4) {
                            Image(systemName: "dumbbell.fill")
                            Text(timerInterval: state.startTime...Date.distantFuture, countsDown: false)
                                .monospacedDigit()
                        }
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                    }
                    .foregroundStyle(restAmber)

                    restProgressBar(state: state)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 15))
                    Text(timerInterval: state.startTime...Date.distantFuture, countsDown: false)
                        .font(.system(.title3, design: .rounded).monospacedDigit())
                }
                .foregroundStyle(neonGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
}
