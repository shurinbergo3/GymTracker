//
//  HealthStatsCard.swift
//  GymTracker
//
//  Apple Health summary card: steps, cardio fitness (VO2 Max),
//  exercise minutes, weekly workouts and resting energy.
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
    case resting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .steps:    return "Шаги".localized()
        case .cardio:   return "Кардио".localized()
        case .exercise: return "Упражнения".localized()
        case .workouts: return "Тренировки".localized()
        case .resting:  return "Энергия покоя".localized()
        }
    }

    var icon: String {
        switch self {
        case .steps:    return "figure.walk"
        case .cardio:   return "heart.text.square.fill"
        case .exercise: return "flame.fill"
        case .workouts: return "dumbbell.fill"
        case .resting:  return "bed.double.fill"
        }
    }

    var accent: Color {
        switch self {
        case .steps:    return Color(red: 0.45, green: 0.85, blue: 1.0)   // sky
        case .cardio:   return Color(red: 1.0,  green: 0.35, blue: 0.45)  // red
        case .exercise: return DesignSystem.Colors.neonGreen              // neon
        case .workouts: return Color(red: 1.0,  green: 0.65, blue: 0.0)   // amber
        case .resting:  return Color(red: 0.6,  green: 0.4,  blue: 1.0)   // purple
        }
    }
}

// MARK: - Aggregated Health Stats

@MainActor
private final class HealthStatsViewModel: ObservableObject {
    @Published var stepsToday: Int = 0
    @Published var stepsWeek: Int = 0
    @Published var dailySteps: [DailyHealthValue] = []

    @Published var vo2Max: Double = 0
    @Published var exerciseMinutesToday: Int = 0
    @Published var exerciseMinutesWeek: Int = 0
    @Published var dailyExerciseMinutes: [DailyHealthValue] = []

    @Published var workoutsThisWeek: Int = 0
    @Published var dailyWorkoutCounts: [DailyHealthValue] = []

    @Published var restingEnergyToday: Int = 0
    @Published var dailyResting: [DailyHealthValue] = []

    @Published var isLoading: Bool = false

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        // Make sure we have authorization before issuing queries.
        if !HealthManager.shared.isAuthorized {
            _ = await HealthManager.shared.requestAuthorization()
        }
        guard HealthManager.shared.isAuthorized else { return }

        async let steps7 = HealthManager.shared.fetchDailySteps(days: 7)
        async let exercise7 = HealthManager.shared.fetchDailyExerciseMinutes(days: 7)
        async let resting7 = HealthManager.shared.fetchDailyBasalEnergy(days: 7)
        async let workouts7 = HealthManager.shared.fetchDailyWorkoutCounts(days: 7)
        async let vo2 = HealthManager.shared.fetchVO2Max()
        async let basalToday = HealthManager.shared.fetchTodayBasalEnergy()
        async let workoutsTotal = HealthManager.shared.fetchWorkoutsThisWeek()

        let stepsValues = await steps7
        let exerciseValues = await exercise7
        let restingValues = await resting7
        let workoutValues = await workouts7
        let vo2Value = await vo2
        let basalTodayValue = await basalToday
        let workoutsTotalValue = await workoutsTotal

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
    }
}

// MARK: - Main Card

struct HealthStatsCard: View {
    @StateObject private var vm = HealthStatsViewModel()
    @State private var selectedStat: HealthStatKind?

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            LazyVGrid(columns: columns, spacing: 12) {
                tile(.steps, value: formatNumber(vm.stepsToday), subtitle: weekSubtitle(total: vm.stepsWeek, suffix: "шагов".localized()))
                tile(.cardio, value: vm.vo2Max > 0 ? String(format: "%.1f", vm.vo2Max) : "—", subtitle: "VO₂ \("за 30 дней".localized())")
                tile(.exercise, value: "\(vm.exerciseMinutesToday)", subtitle: "\(vm.exerciseMinutesWeek) \("мин/нед".localized())")
                tile(.workouts, value: "\(vm.workoutsThisWeek)", subtitle: "за неделю".localized())
            }

            // Wide tile for Resting Energy
            wideTile(
                .resting,
                value: "\(vm.restingEnergyToday)",
                unit: "ккал".localized(),
                subtitle: "сегодня".localized(),
                weekTotal: Int(vm.dailyResting.reduce(0) { $0 + $1.value })
            )
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
            await vm.load()
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
            } else {
                Text("за неделю".localized().uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
                    .tracking(1.2)
            }
        }
    }

    @ViewBuilder
    private func tile(_ kind: HealthStatKind, value: String, subtitle: String) -> some View {
        Button {
            selectedStat = kind
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: kind.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(kind.accent)
                        .frame(width: 28, height: 28)
                        .background(kind.accent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                }

                Text(kind.title.uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.0)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .lineLimit(1)

                Text(value)
                    .font(DesignSystem.Typography.monospaced(.title2, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(kind.accent.opacity(0.18), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func wideTile(_ kind: HealthStatKind, value: String, unit: String, subtitle: String, weekTotal: Int) -> some View {
        Button {
            selectedStat = kind
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: kind.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(kind.accent)
                    .frame(width: 38, height: 38)
                    .background(kind.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title.uppercased())
                        .font(DesignSystem.Typography.sectionHeader())
                        .tracking(1.0)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(value)
                            .font(DesignSystem.Typography.monospaced(.title2, weight: .bold))
                            .foregroundStyle(DesignSystem.Colors.primaryText)
                        Text(unit)
                            .font(DesignSystem.Typography.monospaced(.caption, weight: .semibold))
                            .foregroundStyle(kind.accent)
                        Text("· \(subtitle)")
                            .font(.system(size: 11))
                            .foregroundStyle(DesignSystem.Colors.tertiaryText)
                    }
                }

                Spacer()

                // Sparkline mini-graph
                miniSparkline(values: vm.dailyResting.map { $0.value }, color: kind.accent)
                    .frame(width: 70, height: 30)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(kind.accent.opacity(0.18), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func miniSparkline(values: [Double], color: Color) -> some View {
        if values.contains(where: { $0 > 0 }) {
            Chart {
                ForEach(Array(values.enumerated()), id: \.offset) { idx, v in
                    BarMark(
                        x: .value("d", idx),
                        y: .value("v", v)
                    )
                    .foregroundStyle(color.gradient)
                    .cornerRadius(2)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
        } else {
            EmptyView()
        }
    }

    // MARK: - Helpers
    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func weekSubtitle(total: Int, suffix: String) -> String {
        "\(formatNumber(total)) \(suffix)"
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
                    chartBlock
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

            Text(footerHint)
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
        case .steps:    return formatInt(vm.stepsToday)
        case .cardio:   return vm.vo2Max > 0 ? String(format: "%.1f", vm.vo2Max) : "—"
        case .exercise: return "\(vm.exerciseMinutesToday)"
        case .workouts: return "\(vm.workoutsThisWeek)"
        case .resting:  return "\(vm.restingEnergyToday)"
        }
    }

    private var primaryUnit: String {
        switch stat {
        case .steps:    return "шагов".localized()
        case .cardio:   return "мл/кг·мин".localized()
        case .exercise: return "мин".localized()
        case .workouts: return "за неделю".localized()
        case .resting:  return "ккал".localized()
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
        case .resting:
            return "сегодня".localized() + " · " + "энергия в покое".localized()
        }
    }

    private var chartData: [DailyHealthValue]? {
        switch stat {
        case .steps:    return vm.dailySteps
        case .exercise: return vm.dailyExerciseMinutes
        case .workouts: return vm.dailyWorkoutCounts
        case .resting:  return vm.dailyResting
        case .cardio:   return nil // single value, no per-day series
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

    private var footerHint: String {
        "Данные синхронизируются из Apple Health".localized()
    }

    private func formatInt(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HealthStatsCard()
            .padding()
    }
}
