//
//  AchievementsHubCard.swift
//  GymTracker
//
//  Bright, motivating hub used when the user has no Apple Watch /
//  Activity Rings data. Shows level, XP progress, weekly goal,
//  total workouts and next milestone — so progress feels rewarding
//  even without ring data.
//

import SwiftUI

// MARK: - Milestones

private struct AchievementMilestone {
    let workouts: Int
    let title: String
    let icon: String
    let tint: Color
}

private let milestones: [AchievementMilestone] = [
    .init(workouts: 1,   title: "Первая",      icon: "flag.fill",            tint: .green),
    .init(workouts: 5,   title: "Бронза",      icon: "medal.fill",           tint: Color(red: 0.85, green: 0.55, blue: 0.30)),
    .init(workouts: 15,  title: "Серебро",     icon: "medal.fill",           tint: Color(white: 0.78)),
    .init(workouts: 30,  title: "Золото",      icon: "medal.fill",           tint: Color(red: 1.0, green: 0.82, blue: 0.20)),
    .init(workouts: 50,  title: "Платина",     icon: "rosette",              tint: Color(red: 0.5,  green: 0.85, blue: 1.0)),
    .init(workouts: 100, title: "Легенда",     icon: "crown.fill",           tint: Color(red: 1.0,  green: 0.4,  blue: 0.85))
]

// MARK: - Card

struct AchievementsHubCard: View {
    let totalWorkouts: Int
    let workoutsThisWeek: Int
    let weeklyGoal: Int

    private var level: Int { max(1, totalWorkouts / 5 + 1) }
    private var xpInLevel: Int { totalWorkouts % 5 }
    private var xpProgress: Double { Double(xpInLevel) / 5.0 }

    private var nextMilestone: AchievementMilestone? {
        milestones.first { $0.workouts > totalWorkouts }
    }

    private var unlockedCount: Int {
        milestones.filter { $0.workouts <= totalWorkouts }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            xpBar
            milestonesRow
            footerRow
        }
        .padding(DesignSystem.Spacing.lg)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.45),
                            DesignSystem.Colors.accentPurple.opacity(0.35),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.18), radius: 18, x: 0, y: 8)
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.7, blue: 0.2),
                                Color(red: 1.0, green: 0.4, blue: 0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: Color(red: 1.0, green: 0.55, blue: 0.2).opacity(0.6), radius: 12)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.black)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Уровень \(level)".localized().localizedUppercase)
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.4)
                    .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.2))

                Text(athleteTitle(for: level))
                    .font(DesignSystem.Typography.title2())
                    .foregroundStyle(DesignSystem.Colors.primaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(totalWorkouts)")
                    .font(DesignSystem.Typography.monospaced(.title2, weight: .heavy))
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                Text("тренировок".localized().uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.0)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
        }
    }

    // MARK: - XP bar
    private var xpBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("XP до следующего уровня".localized())
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                Spacer()
                Text("\(xpInLevel)/5")
                    .font(DesignSystem.Typography.monospaced(.caption, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.2))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.2),
                                    Color(red: 1.0, green: 0.4, blue: 0.55),
                                    DesignSystem.Colors.accentPurple
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * xpProgress), height: 10)
                        .shadow(color: Color(red: 1.0, green: 0.55, blue: 0.2).opacity(0.5), radius: 6, x: 0, y: 2)
                }
            }
            .frame(height: 10)
        }
    }

    // MARK: - Milestones row
    private var milestonesRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(milestones.enumerated()), id: \.offset) { idx, milestone in
                let unlocked = milestone.workouts <= totalWorkouts
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(unlocked ? milestone.tint.opacity(0.18) : Color.white.opacity(0.04))
                            .frame(width: 38, height: 38)
                        Image(systemName: unlocked ? milestone.icon : "lock.fill")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(unlocked ? milestone.tint : DesignSystem.Colors.tertiaryText)
                    }
                    .overlay(
                        Circle().stroke(
                            unlocked ? milestone.tint.opacity(0.35) : Color.clear,
                            lineWidth: 1
                        )
                    )

                    Text("\(milestone.workouts)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(unlocked ? milestone.tint : DesignSystem.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Footer
    private var footerRow: some View {
        HStack(spacing: 10) {
            // Weekly goal
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
                Text("\(min(workoutsThisWeek, weeklyGoal))/\(weeklyGoal)")
                    .font(DesignSystem.Typography.monospaced(.subheadline, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                Text("за неделю".localized())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(DesignSystem.Colors.neonGreen.opacity(0.10))
            .overlay(Capsule().stroke(DesignSystem.Colors.neonGreen.opacity(0.25), lineWidth: 0.5))
            .clipShape(Capsule())

            Spacer()

            // Next milestone hint
            if let next = nextMilestone {
                let remaining = next.workouts - totalWorkouts
                HStack(spacing: 6) {
                    Image(systemName: next.icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(next.tint)
                    Text("\("ещё".localized()) \(remaining) → \(next.title)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                }
            } else {
                Text("Все награды собраны 🏆".localized())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.20))
            }
        }
    }

    // MARK: - Helpers
    private func athleteTitle(for level: Int) -> String {
        switch level {
        case 1...2:   return "Новичок".localized()
        case 3...5:   return "Любитель".localized()
        case 6...10:  return "Атлет".localized()
        case 11...20: return "Профи".localized()
        default:      return "Легенда".localized()
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.10, blue: 0.10),
                    Color(red: 0.07, green: 0.05, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color(red: 1.0, green: 0.55, blue: 0.20).opacity(0.18), .clear],
                center: .topLeading,
                startRadius: 4,
                endRadius: 220
            )
            RadialGradient(
                colors: [DesignSystem.Colors.accentPurple.opacity(0.16), .clear],
                center: .bottomTrailing,
                startRadius: 4,
                endRadius: 220
            )
        }
    }
}

// MARK: - Smart wrapper that picks card based on Activity Rings availability

struct ActivityHeroSection: View {
    let totalWorkouts: Int
    let workoutsThisWeek: Int
    var weeklyGoal: Int = 4

    @State private var hasActivityRingsData: Bool? = nil  // nil = not yet checked

    var body: some View {
        Group {
            switch hasActivityRingsData {
            case .some(true):
                ActivityRingsCard()
            case .some(false):
                AchievementsHubCard(
                    totalWorkouts: totalWorkouts,
                    workoutsThisWeek: workoutsThisWeek,
                    weeklyGoal: weeklyGoal
                )
            case .none:
                // Skeleton placeholder while we figure out which one to show
                AchievementsHubCard(
                    totalWorkouts: totalWorkouts,
                    workoutsThisWeek: workoutsThisWeek,
                    weeklyGoal: weeklyGoal
                )
                .opacity(0.001) // invisible until we decide
            }
        }
        .task {
            await detectActivityRings()
        }
    }

    private func detectActivityRings() async {
        // Avoid re-detecting on every appear
        guard hasActivityRingsData == nil else { return }

        // If HealthKit not authorized at all, definitely no rings
        if !HealthManager.shared.isAuthorized {
            await MainActor.run { self.hasActivityRingsData = false }
            return
        }

        let summary = await HealthManager.shared.fetchActivitySummary()
        let hasData: Bool = {
            guard let s = summary else { return false }
            let move = s.activeEnergyBurned.doubleValue(for: .kilocalorie())
            let stand = s.appleStandHours.doubleValue(for: .count())
            let exercise = s.appleExerciseTime.doubleValue(for: .minute())
            // Rings only meaningful if there is any input
            return move > 1 || stand > 0 || exercise > 0
        }()

        await MainActor.run {
            self.hasActivityRingsData = hasData
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            AchievementsHubCard(totalWorkouts: 12, workoutsThisWeek: 2, weeklyGoal: 4)
            AchievementsHubCard(totalWorkouts: 47, workoutsThisWeek: 5, weeklyGoal: 4)
        }
        .padding()
    }
}
