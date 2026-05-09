//
//  WeeklyWrapped.swift
//  GymTracker
//
//  "Spotify-Wrapped"-style summary of the user's training week.
//
//  Three pieces in one file (kept together so a feature edit is one PR):
//  • WeeklyWrappedSnapshot      — pure data the cards consume
//  • WeeklyWrappedGenerator     — builds the snapshot from SwiftData
//  • WeeklyWrappedView          — full-screen stories carousel + sharing
//
//  Sharing renders a 9:16 card with the Body Forge logo + app name and pushes
//  it into UIActivityViewController so users can drop it straight into
//  Instagram Stories / TikTok / wherever.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Snapshot

struct WeeklyWrappedSnapshot: Identifiable {
    /// Stable id keyed off the week boundary so SwiftUI's `fullScreenCover(item:)`
    /// treats two snapshots for the same week as identical and doesn't re-mount.
    var id: TimeInterval { weekStart.timeIntervalSince1970 }
    let weekStart: Date
    let weekEnd: Date
    let workoutCount: Int
    let prevWeekWorkoutCount: Int
    let totalVolumeKg: Double
    let prevWeekVolumeKg: Double
    let totalActiveMinutes: Int
    let totalCalories: Int
    let totalSets: Int
    let distinctExercises: Int
    let topExerciseName: String?
    let topExerciseVolumeKg: Double
    let prCount: Int
    let topPRName: String?
    let avgHeartRate: Int?
    let currentStreakDays: Int

    var isEmpty: Bool { workoutCount == 0 }

    var workoutDelta: Int { workoutCount - prevWeekWorkoutCount }
    var volumeDeltaPercent: Int {
        guard prevWeekVolumeKg > 0 else { return 0 }
        return Int(((totalVolumeKg - prevWeekVolumeKg) / prevWeekVolumeKg) * 100)
    }
}

// MARK: - Volume comparison ("это как 1 слон")

/// Fun motivational comparison of the week's total tonnage to a familiar object.
/// Picks the largest object whose count is ≥1, capping at 9 of that object before
/// stepping up to a heavier reference. The whole point is to make a big number
/// land emotionally — "you lifted an elephant" reads better than "5832 kg".
struct WeeklyVolumeComparison {
    let emoji: String
    let count: Int
    let oneForm: String   // "слон"
    let fewForm: String   // "слона"
    let manyForm: String  // "слонов"

    var pluralizedNoun: String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod10 == 1 && mod100 != 11 { return oneForm }
        if mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14) { return fewForm }
        return manyForm
    }

    var displayText: String { "\(count) \(pluralizedNoun)" }

    static func make(forKg kg: Double) -> WeeklyVolumeComparison? {
        guard kg > 0 else { return nil }
        // Ordered light → heavy. We pick the heaviest reference that still gives count ≥ 1.
        let table: [(weightKg: Double, emoji: String, one: String, few: String, many: String)] = [
            (5,      "🍉", "арбуз",     "арбуза",     "арбузов"),
            (50,     "🐧", "пингвин",   "пингвина",   "пингвинов"),
            (90,     "🐺", "волк",      "волка",      "волков"),
            (200,    "🐅", "тигр",      "тигра",      "тигров"),
            (500,    "🎹", "рояль",     "рояля",      "роялей"),
            (700,    "🐎", "конь",      "коня",       "коней"),
            (1500,   "🦛", "бегемот",   "бегемота",   "бегемотов"),
            (2300,   "🦏", "носорог",   "носорога",   "носорогов"),
            (5500,   "🐘", "слон",      "слона",      "слонов"),
            (26000,  "🚜", "трактор",   "трактора",   "тракторов"),
            (40000,  "🚛", "грузовик",  "грузовика",  "грузовиков"),
            (150000, "🐋", "кит",       "кита",       "китов")
        ]

        var best: (Int, (Double, String, String, String, String))? = nil
        for entry in table {
            let n = Int((kg / entry.weightKg).rounded())
            if n >= 1 {
                best = (n, (entry.weightKg, entry.emoji, entry.one, entry.few, entry.many))
            }
        }
        guard let (count, info) = best else { return nil }
        return WeeklyVolumeComparison(
            emoji: info.1, count: count, oneForm: info.2, fewForm: info.3, manyForm: info.4
        )
    }
}

// MARK: - Generator

@MainActor
enum WeeklyWrappedGenerator {

    /// Builds a snapshot covering Monday → Sunday of the week containing
    /// `referenceDate` (defaults to "now"). Pure read — does not mutate state.
    static func make(modelContext: ModelContext, referenceDate: Date = Date()) -> WeeklyWrappedSnapshot {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2  // Monday

        let today = cal.startOfDay(for: referenceDate)
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let weekStart = cal.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) ?? today
        let prevWeekStart = cal.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart

        // Pull every completed session from prevWeekStart onward — we need both windows.
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true && $0.date >= prevWeekStart },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let sessions = (try? modelContext.fetch(descriptor)) ?? []

        let thisWeek = sessions.filter { $0.date >= weekStart && $0.date < weekEnd }
        let prevWeek = sessions.filter { $0.date >= prevWeekStart && $0.date < weekStart }

        // Volume per session = Σ (weight × reps) of completed sets.
        func volume(of group: [WorkoutSession]) -> Double {
            group.reduce(0.0) { acc, session in
                acc + session.sets
                    .filter { $0.isCompleted }
                    .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
            }
        }
        let totalVolume = volume(of: thisWeek)
        let prevVolume  = volume(of: prevWeek)

        let totalCalories = thisWeek.reduce(0) { $0 + ($1.calories ?? 0) }

        let totalSets = thisWeek.reduce(0) { $0 + $1.sets.filter { $0.isCompleted }.count }
        let distinctExerciseNames = Set(thisWeek.flatMap { $0.sets }
            .filter { $0.isCompleted }
            .map { $0.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty })

        let totalMinutes = thisWeek.reduce(0) { acc, s in
            guard let end = s.endTime else { return acc }
            return acc + max(0, Int(end.timeIntervalSince(s.date) / 60))
        }

        // Top exercise of the week by total volume.
        var byExercise: [String: Double] = [:]
        for session in thisWeek {
            for set in session.sets where set.isCompleted && set.weight > 0 && set.reps > 0 {
                let name = set.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                byExercise[name, default: 0] += set.weight * Double(set.reps)
            }
        }
        let top = byExercise.max { $0.value < $1.value }

        // PRs that *fell within this week* — uses the existing PR engine across all
        // history so we get an authoritative answer.
        let allCompletedDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let allCompleted = (try? modelContext.fetch(allCompletedDescriptor)) ?? []
        let allPRs = PersonalRecordsService.recentPRs(from: allCompleted, limit: 200)
        let weekPRs = allPRs.filter { $0.date >= weekStart && $0.date < weekEnd }

        // Average heart rate over the week (only sessions that have one).
        let withHR = thisWeek.compactMap { $0.averageHeartRate }
        let avgHR = withHR.isEmpty ? nil : (withHR.reduce(0, +) / withHR.count)

        // Current streak — reuse the canonical helper so all three views agree.
        let streak = AICoachNotificationService.currentStreakDays(modelContext: modelContext)

        return WeeklyWrappedSnapshot(
            weekStart: weekStart,
            weekEnd: weekEnd.addingTimeInterval(-1),
            workoutCount: thisWeek.count,
            prevWeekWorkoutCount: prevWeek.count,
            totalVolumeKg: totalVolume,
            prevWeekVolumeKg: prevVolume,
            totalActiveMinutes: totalMinutes,
            totalCalories: totalCalories,
            totalSets: totalSets,
            distinctExercises: distinctExerciseNames.count,
            topExerciseName: top?.key,
            topExerciseVolumeKg: top?.value ?? 0,
            prCount: weekPRs.count,
            topPRName: weekPRs.first?.exerciseName,
            avgHeartRate: avgHR,
            currentStreakDays: streak
        )
    }
}

// MARK: - View (single-slide summary, no scroll, staggered reveal)

/// One-frame "credits roll" summary. Designed to fit a single screen on every
/// iPhone from SE to Pro Max — `Spacer`s soak any extra room, every block has a
/// `minimumScaleFactor` so type bends rather than overflows.
///
/// Animation: each block enters on its own delay, riding a unified spring.
/// Together they read like the final frame of a sports documentary — name, date,
/// the headline number, supporting stats, then the call to action drops in last.
struct WeeklyWrappedView: View {
    let snapshot: WeeklyWrappedSnapshot
    let onClose: () -> Void

    @State private var revealed = false

    /// Master spring for every reveal — keeps the stagger feeling "on the same beat".
    private static let revealSpring = Animation.spring(response: 0.6, dampingFraction: 0.78)

    var body: some View {
        ZStack {
            WeeklyWrappedBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 18)
                    .padding(.top, 6)

                // Scrollable so every iPhone — from SE to Pro Max — can reach
                // the bottom of the recap without the share button getting
                // clipped by the home indicator.
                ScrollView(showsIndicators: false) {
                    content
                        .padding(.top, 6)
                        .padding(.bottom, 16)
                }

                shareButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                    .reveal(at: 0.95, revealed: revealed, animation: Self.revealSpring)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Tiny delay so SwiftUI commits the initial (hidden) layout *before*
            // we flip the flag — otherwise the spring snaps with no animation.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                revealed = true
            }
        }
    }

    // MARK: - Top bar

    /// Just a floating close button — the brand mark is the hero, not a topbar
    /// element, so the rest of the screen breathes.
    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                onClose()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 0.5))
            }
            .opacity(revealed ? 1 : 0)
            .animation(Self.revealSpring.delay(0.1), value: revealed)
        }
    }

    // MARK: - Static content (no scroll)

    private var content: some View {
        VStack(spacing: 12) {
            brandHero
                .reveal(at: 0.05, revealed: revealed, animation: Self.revealSpring, scaleFrom: 0.55)

            headerBlock
                .reveal(at: 0.15, revealed: revealed, animation: Self.revealSpring)

            tonnageHero
                .reveal(at: 0.22, revealed: revealed, animation: Self.revealSpring)

            if let comp = WeeklyVolumeComparison.make(forKg: snapshot.totalVolumeKg) {
                comparisonBlock(comp)
                    .reveal(at: 0.30, revealed: revealed, animation: Self.revealSpring, scaleFrom: 0.85)
            }

            statsGrid
                .reveal(at: 0.38, revealed: revealed, animation: Self.revealSpring)

            highlightsStack
        }
        .padding(.horizontal, 18)
    }

    // MARK: Hero — big centered brand logo with neon halo + wordmark

    private var brandHero: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.neonGreen.opacity(0.55))
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                Circle()
                    .fill(DesignSystem.Colors.neonGreen.opacity(0.30))
                    .frame(width: 140, height: 140)
                    .blur(radius: 32)

                Image("BrandLogo")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.65), radius: 22)
                    .shadow(color: .black.opacity(0.5), radius: 14, x: 0, y: 8)
                    .scaleEffect(revealed ? 1.0 : 0.92)
            }
            .frame(height: 130)

            Text("BODY FORGE")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .tracking(6)
                .foregroundStyle(.white)
                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.35), radius: 10)
        }
    }

    // MARK: Eyebrow + week range

    private var headerBlock: some View {
        VStack(spacing: 6) {
            Text("Твоя неделя".localized().localizedUppercase)
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .tracking(3.6)
                .foregroundStyle(.white.opacity(0.7))

            Text(weekRangeText)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, DesignSystem.Colors.neonGreen.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .tracking(0.5)
        }
    }

    // MARK: Tonnage block

    private var tonnageHero: some View {
        VStack(spacing: 8) {
            Text(heroTonnage)
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, DesignSystem.Colors.neonGreen],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.55), radius: 22)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            HStack(spacing: 8) {
                Text("Поднято за неделю".localized().localizedUppercase)
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.72))

                if let delta = heroDelta {
                    HStack(spacing: 3) {
                        Image(systemName: delta.icon)
                            .font(.system(size: 9, weight: .heavy))
                        Text(delta.text)
                            .font(.system(.caption2, design: .rounded, weight: .heavy))
                    }
                    .foregroundStyle(delta.color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(delta.color.opacity(0.22))
                    .overlay(Capsule().stroke(delta.color.opacity(0.4), lineWidth: 0.5))
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(GlassPanel(cornerRadius: 24))
    }

    // MARK: Comparison ("это как 1 слон") — gives the abstract tonnage a body.

    private func comparisonBlock(_ comp: WeeklyVolumeComparison) -> some View {
        HStack(spacing: 14) {
            Text(comp.emoji)
                .font(.system(size: 38))
                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.4), radius: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text("Это как".localized().localizedUppercase)
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.65))
                Text(comp.displayText)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, DesignSystem.Colors.neonGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(GlassPanel(cornerRadius: 20))
    }

    // MARK: 6-up stats (2 rows × 3 cells)

    private var statsGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                statColumn(value: "\(snapshot.workoutCount)", label: "трен.".localized())
                statDivider
                statColumn(value: "\(snapshot.totalSets)", label: "подходов".localized())
                statDivider
                statColumn(value: "\(snapshot.distinctExercises)", label: "упражнений".localized())
            }
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 1)
                .padding(.horizontal, 4)
            HStack(spacing: 0) {
                statColumn(
                    value: snapshot.totalActiveMinutes > 0 ? "\(snapshot.totalActiveMinutes)" : "—",
                    label: "мин".localized()
                )
                statDivider
                statColumn(
                    value: snapshot.totalCalories > 0 ? "\(snapshot.totalCalories)" : "—",
                    label: "ккал".localized()
                )
                statDivider
                statColumn(
                    value: snapshot.avgHeartRate.map { "\($0)" } ?? "—",
                    label: "Пульс".localized()
                )
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(GlassPanel(cornerRadius: 20))
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(label.localizedUppercase)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.14))
            .frame(width: 1, height: 28)
    }

    // MARK: Highlight rows — only the ones we actually have data for, each
    // fading in on its own beat so the screen "completes itself" smoothly.

    @ViewBuilder
    private var highlightsStack: some View {
        let rows = highlightRows
        VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                highlightRow(row)
                    .reveal(
                        at: 0.45 + Double(idx) * 0.08,
                        revealed: revealed,
                        animation: Self.revealSpring
                    )
            }
        }
    }

    private func highlightRow(_ row: HighlightRow) -> some View {
        HStack(spacing: 14) {
            // Coloured accent rail on the left edge — gives each row a distinct
            // "chapter heading" feel instead of the flat glass-card look.
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [row.iconColor, row.iconColor.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            ZStack {
                Circle()
                    .fill(row.iconColor.opacity(0.22))
                    .frame(width: 40, height: 40)
                Circle()
                    .stroke(row.iconColor.opacity(0.45), lineWidth: 0.8)
                    .frame(width: 40, height: 40)
                Image(systemName: row.icon)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(row.iconColor)
                    .shadow(color: row.iconColor.opacity(0.7), radius: 8)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(row.title.localizedUppercase)
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(row.iconColor.opacity(0.95))
                Text(row.detail)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 8)

            if let badge = row.badge {
                Text(badge)
                    .font(.system(.subheadline, design: .rounded, weight: .black))
                    .foregroundStyle(row.iconColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(row.iconColor.opacity(0.18))
                    )
                    .overlay(
                        Capsule()
                            .stroke(row.iconColor.opacity(0.4), lineWidth: 0.6)
                    )
                    .lineLimit(1)
            }
        }
        .padding(.leading, 0)
        .padding(.trailing, 14)
        .padding(.vertical, 12)
        .background(
            ZStack {
                GlassPanel(cornerRadius: 18)
                LinearGradient(
                    colors: [row.iconColor.opacity(0.12), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        )
    }

    private struct HighlightRow {
        let icon: String
        let iconColor: Color
        let title: String
        let detail: String
        let badge: String?
    }

    private var highlightRows: [HighlightRow] {
        var rows: [HighlightRow] = []
        if let top = snapshot.topExerciseName, snapshot.topExerciseVolumeKg > 0 {
            rows.append(.init(
                icon: "crown.fill",
                iconColor: Color(red: 1.0, green: 0.85, blue: 0.20),
                title: "Чемпион недели".localized(),
                detail: top,
                badge: "\(Int(snapshot.topExerciseVolumeKg)) " + "кг".localized()
            ))
        }
        if snapshot.prCount > 0 {
            rows.append(.init(
                icon: "trophy.fill",
                iconColor: Color(red: 1.0, green: 0.40, blue: 0.50),
                title: "Новые рекорды".localized(),
                detail: snapshot.topPRName ?? "PR".localized(),
                badge: "\(snapshot.prCount) PR"
            ))
        }
        if snapshot.currentStreakDays > 0 {
            rows.append(.init(
                icon: "flame.fill",
                iconColor: Color(red: 1.0, green: 0.55, blue: 0.10),
                title: "Серия".localized(),
                detail: String(format: "%d дней подряд".localized(), snapshot.currentStreakDays),
                badge: nil
            ))
        }
        // HR moved into the stats grid — keep this list focused on standout moments.
        return Array(rows.prefix(3))
    }

    // MARK: Share button

    private var shareButton: some View {
        Button(action: share) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 15, weight: .heavy))
                Text("Поделиться".localized())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .tracking(0.4)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.neonGreen,
                            Color(red: 0.6, green: 0.9, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    LinearGradient(
                        colors: [Color.white.opacity(0.32), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
            )
            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.55), radius: 24, y: 12)
            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.30), radius: 6, y: 2)
        }
    }

    // MARK: - Helpers

    private static let weekFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "d MMMM"
        return df
    }()

    private var weekRangeText: String {
        let start = Self.weekFormatter.string(from: snapshot.weekStart)
        let end = Self.weekFormatter.string(from: snapshot.weekEnd)
        return "\(start) — \(end)".uppercased()
    }

    private var heroTonnage: String {
        if snapshot.totalVolumeKg >= 1000 {
            return String(format: "%.1f т", snapshot.totalVolumeKg / 1000)
        }
        return "\(Int(snapshot.totalVolumeKg)) кг"
    }

    private var heroDelta: (text: String, icon: String, color: Color)? {
        let pct = snapshot.volumeDeltaPercent
        guard pct != 0 else { return nil }
        if pct > 0 {
            return ("+\(pct)%", "arrow.up.right", Color(red: 0.30, green: 0.95, blue: 0.45))
        }
        return ("\(pct)%", "arrow.down.right", Color(red: 1.0, green: 0.42, blue: 0.42))
    }

    private func share() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let card = WeeklyWrappedShareRender(snapshot: snapshot)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = .init(
            width: WeeklyWrappedShareRender.canvasWidth,
            height: WeeklyWrappedShareRender.canvasHeight
        )
        if let img = renderer.uiImage {
            ShareSheetPresenter.present(items: [img])
        }
    }
}

// MARK: - Reusable glass panel

/// Frosted-glass card body. Same recipe used by every block on the wrap so
/// the screen reads as one coherent material rather than four different ones.
private struct GlassPanel: View {
    let cornerRadius: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.06))
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.10), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Reveal modifier

/// Common entrance — fade up + tiny scale, all riding the same spring with a
/// per-element delay. Centralised here so every block on the wrap is on tempo.
private struct RevealModifier: ViewModifier {
    let delay: Double
    let revealed: Bool
    let animation: Animation
    let scaleFrom: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(revealed ? 1 : 0)
            .scaleEffect(revealed ? 1 : scaleFrom, anchor: .center)
            .offset(y: revealed ? 0 : 14)
            .animation(animation.delay(delay), value: revealed)
    }
}

private extension View {
    func reveal(
        at delay: Double,
        revealed: Bool,
        animation: Animation,
        scaleFrom: CGFloat = 0.92
    ) -> some View {
        modifier(RevealModifier(
            delay: delay,
            revealed: revealed,
            animation: animation,
            scaleFrom: scaleFrom
        ))
    }
}

// MARK: - Background

/// Brand launch image, heavily darkened so text remains legible,
/// with subtle neon-green ambient accents matching the rest of the app.
private struct WeeklyWrappedBackground: View {
    var body: some View {
        ZStack {
            Color.black

            Image("LaunchScreen")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 6)
                .opacity(0.38)

            // Vertical dim — readable text on hero/middle, slightly lighter at edges
            LinearGradient(
                colors: [
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.78),
                    Color.black.opacity(0.70)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Brand neon ambient — top
            Circle()
                .fill(DesignSystem.Colors.neonGreen)
                .frame(width: 380, height: 380)
                .blur(radius: 140)
                .offset(x: 120, y: -220)
                .opacity(0.18)

            // Brand neon ambient — bottom
            Circle()
                .fill(DesignSystem.Colors.neonGreen)
                .frame(width: 280, height: 280)
                .blur(radius: 130)
                .offset(x: -110, y: 320)
                .opacity(0.10)
        }
    }
}

// MARK: - Summary card (the actual single-slide content)

struct WeeklyWrappedSummaryCard: View {
    let snapshot: WeeklyWrappedSnapshot
    var includeFooter: Bool = false
    /// Vertical spacing between blocks. Bigger when the card is rendered into
    /// a 9:16 share canvas so it fills more of the taller frame.
    var blockSpacing: CGFloat = 22

    private static let weekFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "d MMMM"
        return df
    }()

    private var weekRangeText: String {
        let start = Self.weekFormatter.string(from: snapshot.weekStart)
        let end = Self.weekFormatter.string(from: snapshot.weekEnd)
        return "\(start) — \(end)".uppercased()
    }

    private var heroTonnage: String {
        if snapshot.totalVolumeKg >= 1000 {
            return String(format: "%.1f т", snapshot.totalVolumeKg / 1000)
        }
        return "\(Int(snapshot.totalVolumeKg)) кг"
    }

    private var heroDelta: (text: String, icon: String, color: Color)? {
        let pct = snapshot.volumeDeltaPercent
        guard pct != 0 else { return nil }
        if pct > 0 {
            return ("+\(pct)%", "arrow.up.right", Color(red: 0.30, green: 0.95, blue: 0.45))
        }
        return ("\(pct)%", "arrow.down.right", Color(red: 1.0, green: 0.42, blue: 0.42))
    }

    var body: some View {
        VStack(spacing: blockSpacing) {
            brandHero
            headerBlock
            tonnageHero
            if let comp = WeeklyVolumeComparison.make(forKg: snapshot.totalVolumeKg) {
                comparisonBlock(comp)
            }
            statsGrid
            highlightsStack

            if includeFooter {
                Spacer(minLength: 16)
                footer
            }
        }
    }

    // MARK: Hero — big centered brand logo with neon halo + wordmark

    private var brandHero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.neonGreen.opacity(0.55))
                    .frame(width: 280, height: 280)
                    .blur(radius: 80)
                Circle()
                    .fill(DesignSystem.Colors.neonGreen.opacity(0.30))
                    .frame(width: 200, height: 200)
                    .blur(radius: 44)

                Image("BrandLogo")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 170, height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 38, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.7), radius: 28)
                    .shadow(color: .black.opacity(0.55), radius: 18, x: 0, y: 10)
            }
            .frame(height: 200)

            Text("BODY FORGE")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .tracking(8)
                .foregroundStyle(.white)
                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.4), radius: 12)
        }
    }

    // MARK: Comparison block (fun motivational comparison)

    private func comparisonBlock(_ comp: WeeklyVolumeComparison) -> some View {
        HStack(spacing: 16) {
            Text(comp.emoji)
                .font(.system(size: 50))
                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.4), radius: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text("Это как".localized().localizedUppercase)
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.65))
                Text(comp.displayText)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, DesignSystem.Colors.neonGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(glassBackground(cornerRadius: 22))
    }

    // MARK: Eyebrow + week range

    private var headerBlock: some View {
        VStack(spacing: 10) {
            Text("Твоя неделя".localized().localizedUppercase)
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .tracking(3.6)
                .foregroundStyle(.white.opacity(0.7))

            Text(weekRangeText)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, DesignSystem.Colors.neonGreen.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .tracking(0.5)
        }
    }

    // MARK: Tonnage hero block

    private var tonnageHero: some View {
        VStack(spacing: 12) {
            Text(heroTonnage)
                .font(.system(size: 76, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, DesignSystem.Colors.neonGreen],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.55), radius: 26)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            HStack(spacing: 8) {
                Text("Поднято за неделю".localized().localizedUppercase)
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.72))

                if let delta = heroDelta {
                    HStack(spacing: 3) {
                        Image(systemName: delta.icon)
                            .font(.system(size: 9, weight: .heavy))
                        Text(delta.text)
                            .font(.system(.caption2, design: .rounded, weight: .heavy))
                    }
                    .foregroundStyle(delta.color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(delta.color.opacity(0.22))
                    .overlay(Capsule().stroke(delta.color.opacity(0.4), lineWidth: 0.5))
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 20)
        .background(glassBackground(cornerRadius: 28))
    }

    // MARK: 6-up stats (2 rows × 3 cells)

    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                statColumn(value: "\(snapshot.workoutCount)", label: "трен.".localized())
                statDivider
                statColumn(value: "\(snapshot.totalSets)", label: "подходов".localized())
                statDivider
                statColumn(value: "\(snapshot.distinctExercises)", label: "упражнений".localized())
            }
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 1)
                .padding(.horizontal, 4)
            HStack(spacing: 0) {
                statColumn(
                    value: snapshot.totalActiveMinutes > 0 ? "\(snapshot.totalActiveMinutes)" : "—",
                    label: "мин".localized()
                )
                statDivider
                statColumn(
                    value: snapshot.totalCalories > 0 ? "\(snapshot.totalCalories)" : "—",
                    label: "ккал".localized()
                )
                statDivider
                statColumn(
                    value: snapshot.avgHeartRate.map { "\($0)" } ?? "—",
                    label: "Пульс".localized()
                )
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(glassBackground(cornerRadius: 22))
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(label.localizedUppercase)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.14))
            .frame(width: 1, height: 34)
    }

    // MARK: Highlight rows

    @ViewBuilder
    private var highlightsStack: some View {
        VStack(spacing: 12) {
            if let top = snapshot.topExerciseName, snapshot.topExerciseVolumeKg > 0 {
                highlightRow(
                    icon: "crown.fill",
                    iconColor: Color(red: 1.0, green: 0.85, blue: 0.20),
                    title: "Чемпион недели".localized(),
                    detail: top,
                    badge: "\(Int(snapshot.topExerciseVolumeKg)) " + "кг".localized()
                )
            }
            if snapshot.prCount > 0 {
                highlightRow(
                    icon: "trophy.fill",
                    iconColor: Color(red: 1.0, green: 0.40, blue: 0.50),
                    title: "Новые рекорды".localized(),
                    detail: snapshot.topPRName ?? "PR".localized(),
                    badge: "\(snapshot.prCount) PR"
                )
            }
            if snapshot.currentStreakDays > 0 {
                highlightRow(
                    icon: "flame.fill",
                    iconColor: Color(red: 1.0, green: 0.55, blue: 0.10),
                    title: "Серия".localized(),
                    detail: String(format: "%d дней подряд".localized(), snapshot.currentStreakDays),
                    badge: nil
                )
            }
        }
    }

    private func highlightRow(icon: String, iconColor: Color, title: String, detail: String, badge: String?) -> some View {
        HStack(spacing: 14) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [iconColor, iconColor.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.22))
                    .frame(width: 44, height: 44)
                Circle()
                    .stroke(iconColor.opacity(0.45), lineWidth: 0.8)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(iconColor)
                    .shadow(color: iconColor.opacity(0.7), radius: 8)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title.localizedUppercase)
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(iconColor.opacity(0.95))
                Text(detail)
                    .font(.system(.callout, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 8)

            if let badge {
                Text(badge)
                    .font(.system(.subheadline, design: .rounded, weight: .black))
                    .foregroundStyle(iconColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(iconColor.opacity(0.18))
                    )
                    .overlay(
                        Capsule()
                            .stroke(iconColor.opacity(0.4), lineWidth: 0.6)
                    )
                    .lineLimit(1)
            }
        }
        .padding(.trailing, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                glassBackground(cornerRadius: 18)
                LinearGradient(
                    colors: [iconColor.opacity(0.12), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        )
    }

    // MARK: Footer (share render only)

    private var footer: some View {
        VStack(spacing: 4) {
            Text("Body Forge — твоя личная кузница тела".localized())
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(.white.opacity(0.92))
            Text("FOR iOS")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .tracking(2)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: Reusable glass

    private func glassBackground(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.06))
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.10), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Share render (9:16 — fills Instagram Stories edge-to-edge)
//
// Stories is 9:16 (1080×1920); a 4:5 image lands centered with empty bars
// top/bottom — exactly the "обрезанный" complaint. We render at 9:16 and let
// the brand background fill the whole frame, with content stretched via a
// larger blockSpacing so the card occupies more vertical space.
private struct WeeklyWrappedShareRender: View {
    let snapshot: WeeklyWrappedSnapshot

    static let canvasWidth: CGFloat = 1080
    static let canvasHeight: CGFloat = 1920

    var body: some View {
        ZStack {
            // Brand launch image, darkened, with neon-green ambient
            ZStack {
                Color.black

                Image("LaunchScreen")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 14)
                    .opacity(0.36)
                    .frame(width: Self.canvasWidth, height: Self.canvasHeight)
                    .clipped()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.55),
                        Color.black.opacity(0.78),
                        Color.black.opacity(0.70)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Circle()
                    .fill(DesignSystem.Colors.neonGreen)
                    .frame(width: 900, height: 900)
                    .blur(radius: 260)
                    .offset(x: 260, y: -560)
                    .opacity(0.22)

                Circle()
                    .fill(DesignSystem.Colors.neonGreen)
                    .frame(width: 620, height: 620)
                    .blur(radius: 240)
                    .offset(x: -240, y: 700)
                    .opacity(0.13)
            }

            // Content fills almost edge-to-edge — no top header, the brand
            // logo lives inside the summary card itself (big, centered).
            // blockSpacing bumped so the card breathes inside the taller 9:16 frame.
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                WeeklyWrappedSummaryCard(
                    snapshot: snapshot,
                    includeFooter: true,
                    blockSpacing: 38
                )
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 64)
            .padding(.vertical, 80)
        }
        .frame(width: Self.canvasWidth, height: Self.canvasHeight)
    }
}

// MARK: - Dashboard teaser

/// Inline pill-style button that lives on the dashboard and pops the wrapped.
/// Visually distinct from the streak strip so users don't conflate them.
struct WeeklyWrappedTeaser: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.4, blue: 1.0),
                                    Color(red: 0.30, green: 0.95, blue: 0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(.black)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Итоги недели".localized())
                        .font(DesignSystem.Typography.body().weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                    Text("Тоннаж · PR · стрик · поделиться".localized())
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.06),
                        Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.10)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

