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

// MARK: - View

struct WeeklyWrappedView: View {
    let snapshot: WeeklyWrappedSnapshot
    let onClose: () -> Void

    @State private var page: Int = 0
    @State private var sharePayload: SharePayload?

    private var pages: [WeeklyWrappedPage] { WeeklyWrappedPage.deck(for: snapshot) }

    var body: some View {
        ZStack {
            // Dynamic gradient bg keyed off the page colour
            LinearGradient(
                colors: [pages[safe: page]?.tint.opacity(0.65) ?? .black, .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        WeeklyWrappedCard(page: pages[i], snapshot: snapshot)
                            .tag(i)
                            .padding(.horizontal, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomBar
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(items: [payload.image])
                .ignoresSafeArea()
        }
    }

    // MARK: Top bar (progress + close)

    private var topBar: some View {
        HStack(spacing: 6) {
            ForEach(pages.indices, id: \.self) { idx in
                Capsule()
                    .fill(idx <= page ? Color.white : Color.white.opacity(0.25))
                    .frame(height: 3)
            }
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: Bottom CTA

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if page > 0 { withAnimation { page -= 1 } }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }
            .opacity(page == 0 ? 0.4 : 1)
            .disabled(page == 0)

            Button(action: share) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 14, weight: .heavy))
                    Text("Поделиться".localized())
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .white.opacity(0.4), radius: 14, y: 4)
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if page < pages.count - 1 { withAnimation { page += 1 } } else { onClose() }
            } label: {
                Image(systemName: page == pages.count - 1 ? "checkmark" : "chevron.right")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
    }

    // MARK: Share

    private func share() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let card = WeeklyWrappedShareCard(page: pages[page], snapshot: snapshot)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = .init(width: 1080, height: 1920)
        if let img = renderer.uiImage {
            sharePayload = SharePayload(image: img)
        }
    }
}

// MARK: - Page model

struct WeeklyWrappedPage: Identifiable {
    let id = UUID()
    let kind: Kind
    let title: String
    let primary: String
    let secondary: String?
    let icon: String
    let tint: Color

    enum Kind { case cover, workouts, volume, top, prs, streak, outro }

    static func deck(for s: WeeklyWrappedSnapshot) -> [WeeklyWrappedPage] {
        let df = DateFormatter()
        df.dateFormat = "d MMM"
        let range = "\(df.string(from: s.weekStart)) — \(df.string(from: s.weekEnd))"

        var deck: [WeeklyWrappedPage] = [
            .init(
                kind: .cover,
                title: "Твоя неделя".localized(),
                primary: range,
                secondary: "Body Forge",
                icon: "sparkles",
                tint: Color(red: 0.6, green: 0.4, blue: 1.0)
            ),
            .init(
                kind: .workouts,
                title: "Тренировки".localized(),
                primary: "\(s.workoutCount)",
                secondary: s.workoutDelta == 0
                    ? "ровно как неделю назад".localized()
                    : (s.workoutDelta > 0
                       ? "+\(s.workoutDelta) к прошлой неделе".localized()
                       : "\(s.workoutDelta) к прошлой неделе".localized()),
                icon: "dumbbell.fill",
                tint: Color(red: 0.30, green: 0.95, blue: 0.45)
            ),
            .init(
                kind: .volume,
                title: "Поднятый тоннаж".localized(),
                primary: tonnageString(s.totalVolumeKg),
                secondary: s.volumeDeltaPercent == 0
                    ? nil
                    : (s.volumeDeltaPercent > 0
                       ? String(format: "+%d%% к неделе ранее".localized(), s.volumeDeltaPercent)
                       : String(format: "%d%% к неделе ранее".localized(), s.volumeDeltaPercent)),
                icon: "scalemass.fill",
                tint: Color(red: 1.00, green: 0.55, blue: 0.10)
            )
        ]

        if let top = s.topExerciseName {
            deck.append(.init(
                kind: .top,
                title: "Чемпион недели".localized(),
                primary: top,
                secondary: String(format: "%.0f kg общим тоннажем".localized(), s.topExerciseVolumeKg),
                icon: "crown.fill",
                tint: Color(red: 1.0, green: 0.85, blue: 0.20)
            ))
        }

        if s.prCount > 0 {
            deck.append(.init(
                kind: .prs,
                title: "Новые рекорды".localized(),
                primary: "\(s.prCount) PR",
                secondary: s.topPRName,
                icon: "trophy.fill",
                tint: Color(red: 1.0, green: 0.27, blue: 0.4)
            ))
        }

        if s.currentStreakDays > 0 {
            deck.append(.init(
                kind: .streak,
                title: "Серия".localized(),
                primary: "\(s.currentStreakDays)",
                secondary: "дней подряд".localized(),
                icon: "flame.fill",
                tint: Color(red: 1.0, green: 0.45, blue: 0.10)
            ))
        }

        deck.append(.init(
            kind: .outro,
            title: "Поделись результатом".localized(),
            primary: "Вперёд".localized(),
            secondary: "Сохрани силу момента".localized(),
            icon: "paperplane.fill",
            tint: Color(red: 0.4, green: 0.65, blue: 1.0)
        ))

        return deck
    }

    private static func tonnageString(_ kg: Double) -> String {
        if kg >= 1000 {
            return String(format: "%.1f т", kg / 1000)
        }
        return "\(Int(kg)) кг"
    }
}

// MARK: - Card view (shared between in-app + share render)

struct WeeklyWrappedCard: View {
    let page: WeeklyWrappedPage
    let snapshot: WeeklyWrappedSnapshot

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.tint.opacity(0.25))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                Image(systemName: page.icon)
                    .font(.system(size: 96, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: page.tint.opacity(0.7), radius: 20)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .tracking(2)
                    .textCase(.uppercase)

                Text(page.primary)
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 8)

                if let s = page.secondary {
                    Text(s)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 12)
                }
            }

            Spacer()

            // Subtle stat chips on the cover only
            if page.kind == .cover {
                statRow
            }
        }
        .padding(.bottom, 30)
        .padding(.top, 20)
    }

    private var statRow: some View {
        HStack(spacing: 10) {
            chip(value: "\(snapshot.workoutCount)", label: "трен.".localized())
            if snapshot.totalActiveMinutes > 0 {
                chip(value: "\(snapshot.totalActiveMinutes)", label: "мин".localized())
            }
            if snapshot.totalCalories > 0 {
                chip(value: "\(snapshot.totalCalories)", label: "ккал".localized())
            }
        }
        .padding(.bottom, 10)
    }

    private func chip(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.10))
        .clipShape(Capsule())
    }
}

// MARK: - Share-only card (9:16 with logo branding)

private struct WeeklyWrappedShareCard: View {
    let page: WeeklyWrappedPage
    let snapshot: WeeklyWrappedSnapshot

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [page.tint, .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // Branded header
                HStack(spacing: 10) {
                    Image("BrandLogo")
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text("Body Forge")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 36)
                .padding(.top, 60)

                Spacer()

                WeeklyWrappedCard(page: page, snapshot: snapshot)
                    .padding(.horizontal, 24)

                Spacer()

                // Footer attribution
                VStack(spacing: 4) {
                    Text("Body Forge — твоя личная кузница тела".localized())
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("Body Forge for iOS")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .tracking(1.2)
                }
                .padding(.bottom, 64)
            }
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

// MARK: - Tiny utility

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
