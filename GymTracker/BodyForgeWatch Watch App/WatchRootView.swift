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

// MARK: - Live wall-clock helper
//
// `TimelineView(.everyMinute)` rebuilds the inner closure once a minute (no
// app-side timer needed, no battery cost on watchOS — the system manages the
// schedule). Use this any time we want to show wall-clock time inside the
// app body. We don't bump to second-precision because the system clock at
// the top of the screen is minute-precision too, and matching it avoids
// confusing micro-desync between the two clocks.

private struct LiveTimeText: View {
    let font: Font
    let color: Color

    init(font: Font, color: Color = .white) {
        self.font = font
        self.color = color
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            Text(context.date, format: .dateTime.hour().minute())
                .font(font)
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }
}

// MARK: - Idle (start workout)

private struct IdleView: View {
    @EnvironmentObject var model: WatchWorkoutModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                IdleHeader()

                if let stats = model.idleStats, stats.totalWorkouts > 0 {
                    IdleStatsCard(stats: stats)
                        .environmentObject(model)
                } else if model.idleStats != nil {
                    // Fresh user — gentle motivator instead of zeros.
                    Text(model.t(
                        en: "Your first workout starts here",
                        ru: "Первая тренировка — здесь",
                        pl: "Pierwszy trening zaczyna się tu"
                    ))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
                }

                Button(action: { model.requestStartWorkout() }) {
                    StartButtonLabel(state: model.startSignalState, t: model.t)
                }
                .buttonStyle(.plain)
                .disabled(model.startSignalState == .sending)
                .padding(.top, 2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }
}

private struct IdleHeader: View {
    var body: some View {
        VStack(spacing: 6) {
            // Hero clock — the watch is, after all, a watch. When no workout
            // is running, surfacing wall-clock time lets the user keep their
            // wrist up for the rare second longer it takes them to decide
            // whether to start training.
            LiveTimeText(
                font: .system(size: 32, weight: .heavy, design: .rounded),
                color: .white
            )

            HStack(spacing: 6) {
                Image("BrandLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Text("Body Forge")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct IdleStatsCard: View {
    @EnvironmentObject var model: WatchWorkoutModel
    let stats: WatchWorkoutModel.IdleStats

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Total workouts hero number.
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(stats.totalWorkouts)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(neonGreen)
                Text(model.t(
                    en: pluralEn(stats.totalWorkouts),
                    ru: pluralRu(stats.totalWorkouts),
                    pl: pluralPl(stats.totalWorkouts)
                ))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
            }

            // Weekly progress: dot row + "X / Y this week"
            if stats.weeklyGoal > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    weeklyDots
                    Text("\(stats.workoutsThisWeek) / \(stats.weeklyGoal) \(model.t(en: "this week", ru: "в неделю", pl: "w tygodniu"))")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            if let last = stats.lastWorkoutDate {
                Text(lastWorkoutLabel(for: last))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private var weeklyDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<min(stats.weeklyGoal, 7), id: \.self) { idx in
                Circle()
                    .fill(idx < stats.workoutsThisWeek ? neonGreen : Color.white.opacity(0.15))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func lastWorkoutLabel(for date: Date) -> String {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: Date())).day ?? 0
        switch days {
        case 0:  return model.t(en: "Last: today", ru: "Последняя: сегодня", pl: "Ostatni: dziś")
        case 1:  return model.t(en: "Last: yesterday", ru: "Последняя: вчера", pl: "Ostatni: wczoraj")
        case 2...6:
            return model.t(
                en: "Last: \(days) days ago",
                ru: "Последняя: \(days) \(daysRu(days)) назад",
                pl: "Ostatni: \(days) \(daysPl(days)) temu"
            )
        default:
            let weeks = days / 7
            return model.t(
                en: "Last: \(weeks) wk ago",
                ru: "Последняя: \(weeks) \(weeksRu(weeks)) назад",
                pl: "Ostatni: \(weeks) \(weeksPl(weeks)) temu"
            )
        }
    }

    // Tiny pluralizers — only the forms we actually need.
    private func pluralEn(_ n: Int) -> String { n == 1 ? "workout" : "workouts" }
    private func pluralRu(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "тренировка" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "тренировки" }
        return "тренировок"
    }
    private func pluralPl(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if n == 1 { return "trening" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "treningi" }
        return "treningów"
    }
    private func daysRu(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "день" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "дня" }
        return "дней"
    }
    private func daysPl(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if n == 1 { return "dzień" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "dni" }
        return "dni"
    }
    private func weeksRu(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "неделю" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "недели" }
        return "недель"
    }
    private func weeksPl(_ n: Int) -> String {
        if n == 1 { return "tydz." }
        return "tyg."
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
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(model.workoutName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    LiveTimeText(
                        font: .caption2.weight(.medium),
                        color: .white.opacity(0.55)
                    )
                }

                Text(model.exerciseName ?? model.workoutName)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                if let setNumber = model.setNumber, let totalSets = model.totalSets, totalSets > 0 {
                    Text("\(model.t(en: "Set", ru: "Подход", pl: "Seria")) \(setNumber) / \(totalSets)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }

                if let lastLine = lastSetSummary {
                    Text(lastLine)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                if model.canCompleteSet {
                    Button(action: { model.requestCompleteSet() }) {
                        CompleteSetButtonLabel(state: model.completeSetState, t: model.t)
                    }
                    .buttonStyle(.plain)
                    .disabled(model.completeSetState == .sending)
                    .padding(.top, 2)
                }

                workoutTimer

                HStack(spacing: 10) {
                    MetricChip(icon: "heart.fill", value: "\(model.heartRate)", color: .red)
                    MetricChip(icon: "flame.fill", value: "\(model.calories)", color: .orange)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
    }

    /// "Last: 50 kg × 8" / "Last: × 8" for reps-only / nil when no data.
    private var lastSetSummary: String? {
        let lastLabel = model.t(en: "Last", ru: "Было", pl: "Ostatnio")
        let reps = model.lastReps
        let weight = model.lastWeight

        if let w = weight, w > 0, let r = reps, r > 0 {
            return "\(lastLabel): \(formatWeight(w)) \(model.lastWeightUnit) × \(r)"
        }
        if let r = reps, r > 0 {
            let repsWord = model.t(en: "reps", ru: "повт.", pl: "powt.")
            return "\(lastLabel): \(r) \(repsWord)"
        }
        return nil
    }

    private func formatWeight(_ w: Double) -> String {
        if w.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", w)
        }
        return String(format: "%.1f", w)
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

/// Variant of `StartButtonLabel` styled for the in-workout "Complete Set"
/// tap. Smaller height than Start (this button lives mid-screen, not on its
/// own page) and uses a check icon to mirror the iPhone-side affordance.
private struct CompleteSetButtonLabel: View {
    let state: WatchWorkoutModel.StartSignalState
    let t: (String, String, String) -> String

    var body: some View {
        HStack(spacing: 6) {
            iconView
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(state == .idle ? .black : Color.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 32)
        .padding(.horizontal, 8)
        .background(backgroundStyle, in: Capsule())
    }

    @ViewBuilder
    private var iconView: some View {
        switch state {
        case .idle:
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.black)
        case .sending:
            ProgressView()
                .scaleEffect(0.55)
                .tint(.white)
        case .sent:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
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
            return t("Complete Set", "Подход выполнен", "Seria gotowa")
        case .sending:
            return t("Sending…", "Отправка…", "Wysyłanie…")
        case .sent:
            return t("Saved", "Сохранено", "Zapisano")
        case .failed:
            return t("Tap iPhone", "Открой iPhone", "Otwórz iPhone")
        }
    }
}

// MARK: - Rest mode (whole-screen takeover)

private struct RestModeView: View {
    @EnvironmentObject var model: WatchWorkoutModel

    var body: some View {
        VStack(spacing: 6) {
            LiveTimeText(
                font: .caption2.weight(.medium),
                color: .white.opacity(0.55)
            )

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

            Button(action: { model.requestSkipRest() }) {
                SkipRestButtonLabel(state: model.skipRestState, t: model.t)
            }
            .buttonStyle(.plain)
            .disabled(model.skipRestState == .sending)
            .padding(.top, 4)

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

/// Outline-style button — secondary action vs. the dominant amber timer.
/// Tapping it skips rest on iPhone so the user can start the next set early.
private struct SkipRestButtonLabel: View {
    let state: WatchWorkoutModel.StartSignalState
    let t: (String, String, String) -> String

    var body: some View {
        HStack(spacing: 5) {
            iconView
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity, minHeight: 28)
        .padding(.horizontal, 8)
        .overlay(
            Capsule().stroke(foreground.opacity(0.55), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var iconView: some View {
        switch state {
        case .idle:
            Image(systemName: "forward.fill")
                .font(.system(size: 11, weight: .semibold))
        case .sending:
            ProgressView()
                .scaleEffect(0.5)
                .tint(restAmber)
        case .sent:
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
        }
    }

    private var foreground: Color {
        switch state {
        case .idle, .sending: return restAmber
        case .sent: return Color.white.opacity(0.85)
        case .failed: return .red
        }
    }

    private var label: String {
        switch state {
        case .idle:
            return t("Skip Rest", "Пропустить", "Pomiń")
        case .sending:
            return t("Sending…", "Отправка…", "Wysyłanie…")
        case .sent:
            return t("Skipped", "Пропущено", "Pominięto")
        case .failed:
            return t("Tap iPhone", "Открой iPhone", "Otwórz iPhone")
        }
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
