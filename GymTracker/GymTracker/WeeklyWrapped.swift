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
            topExerciseName: top?.key,
            topExerciseVolumeKg: top?.value ?? 0,
            prCount: weekPRs.count,
            topPRName: weekPRs.first?.exerciseName,
            avgHeartRate: avgHR,
            currentStreakDays: streak
        )
    }
}

// MARK: - View (single-slide summary)

struct WeeklyWrappedView: View {
    let snapshot: WeeklyWrappedSnapshot
    let onClose: () -> Void

    @State private var sharePayload: SharePayload?

    var body: some View {
        ZStack(alignment: .top) {
            WeeklyWrappedBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    HStack(spacing: 10) {
                        Image("BrandLogo")
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        Text("Body Forge")
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 0.5))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)

                ScrollView(showsIndicators: false) {
                    WeeklyWrappedSummaryCard(snapshot: snapshot)
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                }

                shareButton
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(items: [payload.image])
                .ignoresSafeArea()
        }
    }

    private var shareButton: some View {
        Button(action: share) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 15, weight: .heavy))
                Text("Поделиться".localized())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    Color.white
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
            )
            .shadow(color: .white.opacity(0.35), radius: 24, y: 10)
            .shadow(color: .white.opacity(0.20), radius: 6, y: 2)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
    }

    private func share() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let card = WeeklyWrappedShareRender(snapshot: snapshot)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = .init(width: 1080, height: 1920)
        if let img = renderer.uiImage {
            sharePayload = SharePayload(image: img)
        }
    }
}

// MARK: - Background mesh

private struct WeeklyWrappedBackground: View {
    var body: some View {
        ZStack {
            Color.black

            // Top-right purple
            Circle()
                .fill(Color(red: 0.55, green: 0.30, blue: 1.0))
                .frame(width: 460, height: 460)
                .blur(radius: 110)
                .offset(x: 140, y: -240)
                .opacity(0.85)

            // Mid-left pink
            Circle()
                .fill(Color(red: 1.0, green: 0.30, blue: 0.65))
                .frame(width: 360, height: 360)
                .blur(radius: 110)
                .offset(x: -130, y: 60)
                .opacity(0.65)

            // Bottom warm
            Circle()
                .fill(Color(red: 1.0, green: 0.55, blue: 0.20))
                .frame(width: 340, height: 340)
                .blur(radius: 110)
                .offset(x: 110, y: 380)
                .opacity(0.55)

            // Subtle dimmer
            Color.black.opacity(0.18)
        }
    }
}

// MARK: - Summary card (the actual single-slide content)

struct WeeklyWrappedSummaryCard: View {
    let snapshot: WeeklyWrappedSnapshot
    var includeFooter: Bool = false

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
        VStack(spacing: 22) {
            sparkleHero
            headerBlock
            tonnageHero
            statsGrid
            highlightsStack

            if includeFooter {
                Spacer(minLength: 16)
                footer
            }
        }
    }

    // MARK: Hero icon

    private var sparkleHero: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.85, green: 0.55, blue: 1.0).opacity(0.55))
                .frame(width: 170, height: 170)
                .blur(radius: 50)
            Circle()
                .fill(Color(red: 1.0, green: 0.55, blue: 0.85).opacity(0.35))
                .frame(width: 130, height: 130)
                .blur(radius: 30)
                .offset(x: 24, y: 12)
            Image(systemName: "sparkles")
                .font(.system(size: 64, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(red: 1.0, green: 0.92, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .white.opacity(0.6), radius: 18)
        }
        .frame(height: 130)
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
                        colors: [.white, Color(red: 1.0, green: 0.88, blue: 1.0)],
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
                        colors: [.white, Color(red: 1.0, green: 0.82, blue: 0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 1.0, green: 0.65, blue: 0.30).opacity(0.45), radius: 24)
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

    // MARK: 3-up stats

    private var statsGrid: some View {
        HStack(spacing: 0) {
            statColumn(value: "\(snapshot.workoutCount)", label: "трен.".localized())
            statDivider
            statColumn(
                value: snapshot.totalActiveMinutes > 0 ? "\(snapshot.totalActiveMinutes)" : "—",
                label: "мин".localized()
            )
            statDivider
            statColumn(
                value: snapshot.totalCalories > 0 ? "\(snapshot.totalCalories)" : "—",
                label: "ккал".localized()
            )
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
        VStack(spacing: 10) {
            if let top = snapshot.topExerciseName, snapshot.topExerciseVolumeKg > 0 {
                highlightRow(
                    icon: "crown.fill",
                    iconColor: Color(red: 1.0, green: 0.85, blue: 0.20),
                    title: "Чемпион недели".localized(),
                    detail: "\(top) · \(Int(snapshot.topExerciseVolumeKg)) кг"
                )
            }
            if snapshot.prCount > 0 {
                highlightRow(
                    icon: "trophy.fill",
                    iconColor: Color(red: 1.0, green: 0.40, blue: 0.50),
                    title: "Новые рекорды".localized(),
                    detail: snapshot.topPRName.map { String(format: "%d PR · %@".localized(), snapshot.prCount, $0) } ?? String(format: "%d PR".localized(), snapshot.prCount)
                )
            }
            if snapshot.currentStreakDays > 0 {
                highlightRow(
                    icon: "flame.fill",
                    iconColor: Color(red: 1.0, green: 0.55, blue: 0.10),
                    title: "Серия".localized(),
                    detail: String(format: "%d дней подряд".localized(), snapshot.currentStreakDays)
                )
            }
            if let hr = snapshot.avgHeartRate, hr > 0 {
                highlightRow(
                    icon: "heart.fill",
                    iconColor: Color(red: 1.0, green: 0.30, blue: 0.45),
                    title: "Средний пульс".localized(),
                    detail: String(format: "%d уд./мин".localized(), hr)
                )
            }
        }
    }

    private func highlightRow(icon: String, iconColor: Color, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.22))
                    .frame(width: 42, height: 42)
                Circle()
                    .stroke(iconColor.opacity(0.4), lineWidth: 0.6)
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(iconColor)
                    .shadow(color: iconColor.opacity(0.6), radius: 6)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title.localizedUppercase)
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.65))
                Text(detail)
                    .font(.system(.callout, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(glassBackground(cornerRadius: 18))
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

// MARK: - Share render (9:16 with brand framing)

private struct WeeklyWrappedShareRender: View {
    let snapshot: WeeklyWrappedSnapshot

    var body: some View {
        ZStack {
            // Bigger bleed of the same mesh, scaled for 1080x1920
            ZStack {
                Color.black
                Circle()
                    .fill(Color(red: 0.55, green: 0.30, blue: 1.0))
                    .frame(width: 900, height: 900)
                    .blur(radius: 220)
                    .offset(x: 280, y: -480)
                    .opacity(0.85)
                Circle()
                    .fill(Color(red: 1.0, green: 0.30, blue: 0.65))
                    .frame(width: 720, height: 720)
                    .blur(radius: 220)
                    .offset(x: -240, y: 220)
                    .opacity(0.70)
                Circle()
                    .fill(Color(red: 1.0, green: 0.55, blue: 0.20))
                    .frame(width: 720, height: 720)
                    .blur(radius: 220)
                    .offset(x: 200, y: 760)
                    .opacity(0.55)
                Color.black.opacity(0.15)
            }

            VStack(spacing: 0) {
                // Brand header
                HStack(spacing: 12) {
                    Image("BrandLogo")
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text("Body Forge")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 56)
                .padding(.top, 70)

                Spacer(minLength: 24)

                WeeklyWrappedSummaryCard(snapshot: snapshot, includeFooter: true)
                    .padding(.horizontal, 50)

                Spacer(minLength: 40)
            }
            .padding(.bottom, 56)
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Share sheet wrapper

private struct SharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
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

