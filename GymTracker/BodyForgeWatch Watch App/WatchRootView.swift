//
//  WatchRootView.swift
//  Body Forge Watch App
//

import SwiftUI

// Local palette — kept in sync with the iOS Live Activity colors so the
// watch and phone read as the same product.
private let neonGreen = Color(red: 0.34, green: 0.93, blue: 0.43)
private let restAmber = Color(red: 1.0, green: 0.71, blue: 0.21)

struct WatchRootView: View {
    @EnvironmentObject var model: WatchWorkoutModel

    var body: some View {
        Group {
            if model.isWorkoutActive {
                if model.isResting {
                    RestModeView()
                } else {
                    ActiveWorkoutView()
                }
            } else {
                IdleView()
            }
        }
        .containerBackground(for: .navigation) {
            // Subtle background tint so the rest mode reads as a different
            // visual state without redrawing the whole layout.
            LinearGradient(
                colors: model.isResting
                    ? [Color(red: 0.18, green: 0.10, blue: 0.02), Color.black]
                    : [Color.black, Color(red: 0.07, green: 0.07, blue: 0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .animation(.easeInOut(duration: 0.25), value: model.isResting)
    }
}

// MARK: - Idle (start workout)

private struct IdleView: View {
    @EnvironmentObject var model: WatchWorkoutModel

    var body: some View {
        VStack(spacing: 8) {
            Image("BrandLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)

            Text("Body Forge")
                .font(.headline)

            Spacer(minLength: 2)

            Button(action: { model.requestStartWorkout() }) {
                StartButtonLabel(state: model.startSignalState, t: model.t)
            }
            .buttonStyle(.plain)
            .disabled(model.startSignalState == .sending)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

private struct StartButtonLabel: View {
    let state: WatchWorkoutModel.StartSignalState
    let t: (String, String, String) -> String

    var body: some View {
        HStack(spacing: 6) {
            iconView
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(state == .idle ? .black : Color.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 36)
        .padding(.horizontal, 8)
        .background(backgroundStyle, in: Capsule())
    }

    @ViewBuilder
    private var iconView: some View {
        switch state {
        case .idle:
            Image(systemName: "play.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.black)
        case .sending:
            ProgressView()
                .scaleEffect(0.6)
                .tint(.white)
        case .sent:
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(.white)
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        switch state {
        case .idle: return AnyShapeStyle(neonGreen)
        case .sending: return AnyShapeStyle(Color.white.opacity(0.18))
        case .sent: return AnyShapeStyle(neonGreen.opacity(0.5))
        case .failed: return AnyShapeStyle(Color.red.opacity(0.7))
        }
    }

    private var label: String {
        switch state {
        case .idle:
            return t("Start Workout", "Начать тренировку", "Rozpocznij trening")
        case .sending:
            return t("Sending…", "Отправка…", "Wysyłanie…")
        case .sent:
            return t("Sent to iPhone", "Отправлено", "Wysłano")
        case .failed:
            return t("Tap iPhone", "Открой iPhone", "Otwórz iPhone")
        }
    }
}

// MARK: - Active workout (mirror)

private struct ActiveWorkoutView: View {
    @EnvironmentObject var model: WatchWorkoutModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(model.workoutName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(model.exerciseName ?? model.workoutName)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            if let setNumber = model.setNumber, let totalSets = model.totalSets, totalSets > 0 {
                Text("\(model.t(en: "Set", ru: "Подход", pl: "Seria")) \(setNumber) / \(totalSets)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }

            workoutTimer

            Spacer(minLength: 4)

            HStack(spacing: 10) {
                MetricChip(icon: "heart.fill", value: "\(model.heartRate)", color: .red)
                MetricChip(icon: "flame.fill", value: "\(model.calories)", color: .orange)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var workoutTimer: some View {
        if let startTime = model.startTime {
            Text(timerInterval: startTime...Date.distantFuture, countsDown: false)
                .monospacedDigit()
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(neonGreen)
        } else {
            Text("--:--")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Rest mode (whole-screen takeover)

private struct RestModeView: View {
    @EnvironmentObject var model: WatchWorkoutModel

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "hourglass")
                    .font(.system(size: 14, weight: .semibold))
                Text(model.t(
                    en: "REST",
                    ru: "ОТДЫХ",
                    pl: "ODPOCZYNEK"
                ))
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
            }
            .foregroundStyle(restAmber)

            if let restEndsAt = model.restEndsAt, restEndsAt > Date() {
                Text(timerInterval: Date()...restEndsAt, countsDown: true)
                    .monospacedDigit()
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(restAmber)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            if let setNumber = model.setNumber, let totalSets = model.totalSets, totalSets > 0 {
                Text("\(model.t(en: "Next: Set", ru: "Дальше: подход", pl: "Dalej: seria")) \(setNumber) / \(totalSets)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            } else if let exercise = model.exerciseName {
                Text(exercise)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                MetricChip(icon: "heart.fill", value: "\(model.heartRate)", color: .red)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }
}

private struct MetricChip: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.08), in: Capsule())
    }
}

#Preview {
    WatchRootView()
        .environmentObject(WatchWorkoutModel())
}
