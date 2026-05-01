//
//  HealthStatsCard.swift
//  GymTracker
//
//  Unified Apple Health hub:
//   • Активность   — Шаги, Кардио (VO₂), Упражнения, Тренировки/нед
//   • Восстановление — Сон, Пульс покоя, Пульс на тренировке, Энергия покоя
//
//  Each tile opens a detail sheet with a 7-day chart and breakdown.
//

import SwiftUI
import HealthKit
import Charts

// MARK: - Stat Model

private enum HealthStatKind: String, CaseIterable, Identifiable {
    case steps
    case cardio
    case exercise
    case workouts
    case sleep
    case restingHR
    case workoutHR
    case resting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .steps:     return "Шаги".localized()
        case .cardio:    return "Кардио".localized()
        case .exercise:  return "Упражнения".localized()
        case .workouts:  return "Тренировки".localized()
        case .sleep:     return "Сон".localized()
        case .restingHR: return "Пульс покоя".localized()
        case .workoutHR: return "Пульс трен.".localized()
        case .resting:   return "Энергия покоя".localized()
        }
    }

    var icon: String {
        switch self {
        case .steps:     return "figure.walk"
        case .cardio:    return "heart.text.square.fill"
        case .exercise:  return "flame.fill"
        case .workouts:  return "dumbbell.fill"
        case .sleep:     return "bed.double.fill"
        case .restingHR: return "heart.fill"
        case .workoutHR: return "waveform.path.ecg"
        case .resting:   return "leaf.fill"
        }
    }

    var accent: Color {
        switch self {
        case .steps:     return Color(red: 0.45, green: 0.85, blue: 1.0)   // sky
        case .cardio:    return Color(red: 1.0,  green: 0.35, blue: 0.45)  // red
        case .exercise:  return DesignSystem.Colors.neonGreen              // neon
        case .workouts:  return Color(red: 1.0,  green: 0.65, blue: 0.0)   // amber
        case .sleep:     return Color(red: 0.6,  green: 0.4,  blue: 1.0)   // purple
        case .restingHR: return Color(red: 1.0,  green: 0.45, blue: 0.55)  // pink
        case .workoutHR: return Color(red: 0.35, green: 0.95, blue: 0.7)   // mint
        case .resting:   return Color(red: 0.7,  green: 0.85, blue: 0.4)   // lime
        }
    }
}

// MARK: - Aggregated Health Stats

@MainActor
private final class HealthStatsViewModel: ObservableObject {
    // Activity
    @Published var stepsToday: Int = 0
    @Published var stepsWeek: Int = 0
    @Published var dailySteps: [DailyHealthValue] = []

    @Published var vo2Max: Double = 0
    @Published var exerciseMinutesToday: Int = 0
    @Published var exerciseMinutesWeek: Int = 0
    @Published var dailyExerciseMinutes: [DailyHealthValue] = []

    @Published var workoutsThisWeek: Int = 0
    @Published var dailyWorkoutCounts: [DailyHealthValue] = []

    // Recovery
    @Published var sleepLastNight: TimeInterval = 0   // seconds
    @Published var restingHR: Int = 0
    @Published var workoutHR: Int = 0
    @Published var restingEnergyToday: Int = 0
    @Published var dailyResting: [DailyHealthValue] = []

    @Published var isLoading: Bool = false
    @Published var isAuthorized: Bool = false

    func load(lastWorkoutHR: Int = 0) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        if !HealthManager.shared.isAuthorized {
            _ = await HealthManager.shared.requestAuthorization()
        }
        self.isAuthorized = HealthManager.shared.isAuthorized
        guard isAuthorized else { return }

        async let steps7 = HealthManager.shared.fetchDailySteps(days: 7)
        async let exercise7 = HealthManager.shared.fetchDailyExerciseMinutes(days: 7)
        async let resting7 = HealthManager.shared.fetchDailyBasalEnergy(days: 7)
        async let workouts7 = HealthManager.shared.fetchDailyWorkoutCounts(days: 7)
        async let vo2 = HealthManager.shared.fetchVO2Max()
        async let basalToday = HealthManager.shared.fetchTodayBasalEnergy()
        async let workoutsTotal = HealthManager.shared.fetchWorkoutsThisWeek()
        async let restingHRValue = HealthManager.shared.fetchRestingHeartRate()
        async let sleepData = SleepService.shared.fetchSleepData()

        let stepsValues = await steps7
        let exerciseValues = await exercise7
        let restingValues = await resting7
        let workoutValues = await workouts7
        let vo2Value = await vo2
        let basalTodayValue = await basalToday
        let workoutsTotalValue = await workoutsTotal
        let restingHRRaw = await restingHRValue
        let sleep = await sleepData

        self.dailySteps = stepsValues
        self.stepsWeek = Int(stepsValues.reduce(0) { $0 + $1.value })
        self.stepsToday = Int(stepsValues.last?.value ?? 0)

        self.dailyExerciseMinutes = exerciseValues
        self.exerciseMinutesWeek = Int(exerciseValues.reduce(0) { $0 + $1.value })
        self.exerciseMinutesToday = Int(exerciseValues.last?.value ?? 0)

        self.dailyResting = restingValues
        self.restingEnergyToday = Int(basalTodayValue)

        self.dailyWorkoutCounts = workoutValues
        self.workoutsThisWeek = workoutsTotalValue

        self.vo2Max = vo2Value
        self.restingHR = Int(restingHRRaw)
        self.workoutHR = lastWorkoutHR

        // Compute total sleep duration (excluding inBed)
        let asleepSegments = sleep
            .filter { $0.type != .inBed }
            .sorted { $0.startDate < $1.startDate }
        self.sleepLastNight = SleepService.calculateTotalDuration(from: asleepSegments)
    }
}

// MARK: - Main Card

struct HealthStatsCard: View {
    /// Optional last workout to surface the workout heart-rate stat.
    let lastWorkoutSession: WorkoutSession?

    @StateObject private var vm = HealthStatsViewModel()
    @State private var selectedStat: HealthStatKind?

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    init(lastWorkoutSession: WorkoutSession? = nil) {
        self.lastWorkoutSession = lastWorkoutSession
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            // Section 1: Activity
            sectionHeader("Активность".localized())
            LazyVGrid(columns: columns, spacing: 10) {
                tile(.steps,    value: formatNumber(vm.stepsToday),
                     subtitle: "\(formatNumber(vm.stepsWeek)) " + "за неделю".localized())
                tile(.cardio,   value: vm.vo2Max > 0 ? String(format: "%.1f", vm.vo2Max) : "—",
                     subtitle: "VO₂ · " + "30 дней".localized())
                tile(.exercise, value: "\(vm.exerciseMinutesToday)",
                     subtitle: "\(vm.exerciseMinutesWeek) " + "мин/нед".localized())
                tile(.workouts, value: "\(vm.workoutsThisWeek)",
                     subtitle: "за неделю".localized())
            }

            // Section 2: Recovery
            // Order: heart rate tiles together on the first row, then sleep + resting energy.
            sectionHeader("Восстановление".localized())
            LazyVGrid(columns: columns, spacing: 10) {
                tile(.restingHR,
                     value: vm.restingHR > 0 ? "\(vm.restingHR)" : "—",
                     subtitle: "уд/мин · 7 дн".localized())
                tile(.workoutHR,
                     value: vm.workoutHR > 0 ? "\(vm.workoutHR)" : "—",
                     subtitle: "посл. тренировка".localized())
                tile(.sleep,
                     value: vm.sleepLastNight > 0 ? formatSleep(vm.sleepLastNight) : "—",
                     subtitle: "за ночь".localized())
                tile(.resting,
                     value: "\(vm.restingEnergyToday)",
                     subtitle: "ккал · сегодня".localized())
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            LinearGradient(
                colors: [
                    Color(white: 0.10),
                    Color(white: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
        .task {
            let lastHR = lastWorkoutSession?.averageHeartRate ?? 0
            await vm.load(lastWorkoutHR: lastHR)
        }
        .sheet(item: $selectedStat) { stat in
            HealthStatDetailView(stat: stat, vm: vm)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .red], startPoint: .top, endPoint: .bottom)
                )
                .font(.system(size: 16, weight: .bold))
            Text("Apple Health".localized())
                .font(DesignSystem.Typography.headline())
                .foregroundStyle(DesignSystem.Colors.primaryText)

            Spacer()

            if vm.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(DesignSystem.Colors.secondaryText)
            } else if !vm.isAuthorized {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("нет доступа".localized().uppercased())
                        .font(DesignSystem.Typography.sectionHeader())
                        .tracking(1.0)
                }
                .foregroundStyle(.orange)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("синхронизировано".localized().uppercased())
                        .font(DesignSystem.Typography.sectionHeader())
                        .tracking(1.0)
                }
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(DesignSystem.Typography.sectionHeader())
            .tracking(1.4)
            .foregroundStyle(DesignSystem.Colors.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func tile(_ kind: HealthStatKind, value: String, subtitle: String) -> some View {
        Button {
            selectedStat = kind
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: kind.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(kind.accent)
                        .frame(width: 26, height: 26)
                        .background(kind.accent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                }

                Text(kind.title.uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.0)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .lineLimit(1)

                Text(value)
                    .font(DesignSystem.Typography.monospaced(.title3, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(kind.accent.opacity(0.18), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helpers
    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func formatSleep(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        return "\(h)\("ч".localized()) \(m)\("м".localized())"
    }
}

// MARK: - Detail Sheet

private struct HealthStatDetailView: View {
    let stat: HealthStatKind
    @ObservedObject fileprivate var vm: HealthStatsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroBlock
                    if hasChart {
                        chartBlock
                    }
                    breakdownBlock
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, 40)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle(stat.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done_button".localized()) { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Hero
    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: stat.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(stat.accent)
                    .frame(width: 44, height: 44)
                    .background(stat.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.title.uppercased())
                        .font(DesignSystem.Typography.sectionHeader())
                        .tracking(1.2)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)

                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(primaryValue)
                            .font(DesignSystem.Typography.monospaced(.largeTitle, weight: .heavy))
                            .foregroundStyle(DesignSystem.Colors.primaryText)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)

                        Text(primaryUnit)
                            .font(DesignSystem.Typography.monospaced(.headline, weight: .bold))
                            .foregroundStyle(stat.accent)
                    }
                }
            }

            Text(heroCaption)
                .font(.callout)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [stat.accent.opacity(0.18), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(stat.accent.opacity(0.3), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    // MARK: - Chart
    private var chartBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Последние 7 дней".localized().uppercased())
                .font(DesignSystem.Typography.sectionHeader())
                .tracking(1.2)
                .foregroundStyle(DesignSystem.Colors.secondaryText)

            if let data = chartData, data.contains(where: { $0.value > 0 }) {
                Chart {
                    ForEach(data) { item in
                        BarMark(
                            x: .value("Day", item.date, unit: .day),
                            y: .value("Value", item.value)
                        )
                        .foregroundStyle(stat.accent.gradient)
                        .cornerRadius(6)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.07))
                        AxisValueLabel().foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                }
                .frame(height: 200)
            } else {
                Text("Нет данных".localized())
                    .font(.callout)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }

    // MARK: - Breakdown
    private var breakdownBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Сводка".localized().uppercased())
                .font(DesignSystem.Typography.sectionHeader())
                .tracking(1.2)
                .foregroundStyle(DesignSystem.Colors.secondaryText)

            ForEach(breakdownRows, id: \.0) { row in
                HStack {
                    Text(row.0)
                        .font(.callout)
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                    Spacer()
                    Text(row.1)
                        .font(DesignSystem.Typography.monospaced(.callout, weight: .semibold))
                        .foregroundStyle(stat.accent)
                }
                .padding(.vertical, 6)
                Divider().background(Color.white.opacity(0.06))
            }

            Text("Данные синхронизируются из Apple Health".localized())
                .font(.caption2)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
                .padding(.top, 4)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }

    // MARK: - Per-stat content

    private var primaryValue: String {
        switch stat {
        case .steps:     return formatInt(vm.stepsToday)
        case .cardio:    return vm.vo2Max > 0 ? String(format: "%.1f", vm.vo2Max) : "—"
        case .exercise:  return "\(vm.exerciseMinutesToday)"
        case .workouts:  return "\(vm.workoutsThisWeek)"
        case .sleep:     return vm.sleepLastNight > 0 ? formatSleepHM(vm.sleepLastNight) : "—"
        case .restingHR: return vm.restingHR > 0 ? "\(vm.restingHR)" : "—"
        case .workoutHR: return vm.workoutHR > 0 ? "\(vm.workoutHR)" : "—"
        case .resting:   return "\(vm.restingEnergyToday)"
        }
    }

    private var primaryUnit: String {
        switch stat {
        case .steps:     return "шагов".localized()
        case .cardio:    return "мл/кг·мин".localized()
        case .exercise:  return "мин".localized()
        case .workouts:  return "за неделю".localized()
        case .sleep:     return "за ночь".localized()
        case .restingHR: return "уд/мин".localized()
        case .workoutHR: return "уд/мин".localized()
        case .resting:   return "ккал".localized()
        }
    }

    private var heroCaption: String {
        switch stat {
        case .steps:
            return "сегодня".localized() + " · " + "за неделю".localized() + ": " + formatInt(vm.stepsWeek)
        case .cardio:
            return "среднее VO₂ Max за 30 дней".localized()
        case .exercise:
            return "сегодня".localized() + " · " + "за неделю".localized() + ": " + "\(vm.exerciseMinutesWeek) " + "мин".localized()
        case .workouts:
            return "Apple Health workouts за 7 дней".localized()
        case .sleep:
            return "общая длительность сна за прошлую ночь".localized()
        case .restingHR:
            return "среднее значение пульса в покое за неделю".localized()
        case .workoutHR:
            return "средний пульс на последней тренировке".localized()
        case .resting:
            return "сегодня".localized() + " · " + "энергия в покое".localized()
        }
    }

    private var hasChart: Bool {
        switch stat {
        case .steps, .exercise, .workouts, .resting: return true
        default: return false
        }
    }

    private var chartData: [DailyHealthValue]? {
        switch stat {
        case .steps:    return vm.dailySteps
        case .exercise: return vm.dailyExerciseMinutes
        case .workouts: return vm.dailyWorkoutCounts
        case .resting:  return vm.dailyResting
        default:        return nil
        }
    }

    private var breakdownRows: [(String, String)] {
        switch stat {
        case .steps:
            let avg = vm.dailySteps.isEmpty ? 0 : Int(Double(vm.stepsWeek) / Double(vm.dailySteps.count))
            let best = vm.dailySteps.map { Int($0.value) }.max() ?? 0
            return [
                ("Сегодня".localized(), formatInt(vm.stepsToday)),
                ("За неделю".localized(), formatInt(vm.stepsWeek)),
                ("Среднее в день".localized(), formatInt(avg)),
                ("Лучший день".localized(), formatInt(best))
            ]
        case .cardio:
            return [
                ("Среднее за 30 дней".localized(), vm.vo2Max > 0 ? String(format: "%.1f мл/кг·мин", vm.vo2Max) : "—")
            ]
        case .exercise:
            let avg = vm.dailyExerciseMinutes.isEmpty ? 0 : vm.exerciseMinutesWeek / max(vm.dailyExerciseMinutes.count, 1)
            return [
                ("Сегодня".localized(), "\(vm.exerciseMinutesToday) " + "мин".localized()),
                ("За неделю".localized(), "\(vm.exerciseMinutesWeek) " + "мин".localized()),
                ("Среднее в день".localized(), "\(avg) " + "мин".localized())
            ]
        case .workouts:
            let activeDays = vm.dailyWorkoutCounts.filter { $0.value > 0 }.count
            return [
                ("За неделю".localized(), "\(vm.workoutsThisWeek)"),
                ("Дней с тренировкой".localized(), "\(activeDays)")
            ]
        case .sleep:
            return [
                ("За прошлую ночь".localized(), vm.sleepLastNight > 0 ? formatSleepHM(vm.sleepLastNight) : "—"),
                ("Цель".localized(), "8\("ч".localized()) 0\("м".localized())")
            ]
        case .restingHR:
            return [
                ("Среднее за 7 дней".localized(), vm.restingHR > 0 ? "\(vm.restingHR) уд/мин" : "—")
            ]
        case .workoutHR:
            return [
                ("Последняя тренировка".localized(), vm.workoutHR > 0 ? "\(vm.workoutHR) уд/мин" : "—")
            ]
        case .resting:
            let total = Int(vm.dailyResting.reduce(0) { $0 + $1.value })
            let avg = vm.dailyResting.isEmpty ? 0 : total / max(vm.dailyResting.count, 1)
            return [
                ("Сегодня".localized(), "\(vm.restingEnergyToday) " + "ккал".localized()),
                ("За неделю".localized(), "\(total) " + "ккал".localized()),
                ("Среднее в день".localized(), "\(avg) " + "ккал".localized())
            ]
        }
    }

    private func formatInt(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func formatSleepHM(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        return "\(h)\("ч".localized()) \(m)\("м".localized())"
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HealthStatsCard()
            .padding()
    }
}
