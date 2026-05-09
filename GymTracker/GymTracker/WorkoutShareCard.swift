//
//  WorkoutShareCard.swift
//  GymTracker
//
//  9:16 (1080×1920) share render of a finished workout: brand mark on top,
//  hero stats, % delta vs previous workout, PR badge with per-exercise
//  highlights and per-exercise breakdown. Rendered offscreen via
//  ImageRenderer and pushed to the iOS share sheet.
//

import SwiftUI
import UIKit

// MARK: - Snapshot built from a finished WorkoutSession

struct WorkoutShareSnapshot {
    struct ExerciseLine: Identifiable {
        let id = UUID()
        let name: String
        let bestWeight: Double
        let bestReps: Int
        let totalSets: Int
        let progress: ProgressState?
        /// Previous max weight for this exercise — used for the per-exercise
        /// "+X%" badge. nil when there's no previous data (new exercise).
        let previousBestWeight: Double?
    }

    let workoutDayName: String
    let programName: String?
    let date: Date
    let durationSeconds: TimeInterval
    let totalVolumeKg: Double
    /// Volume of the same workout day's previous session (Σ weight×reps over
    /// completed sets). nil when there's no prior session of this day.
    let previousTotalVolumeKg: Double?
    let totalSets: Int
    let totalReps: Int
    let calories: Int
    let averageHeartRate: Int
    let recordsCount: Int
    let exercises: [ExerciseLine]

    /// % change of total volume vs previous session. nil when prev was 0 or absent.
    var volumeDeltaPercent: Int? {
        guard let prev = previousTotalVolumeKg, prev > 0 else { return nil }
        return Int(((totalVolumeKg - prev) / prev * 100).rounded())
    }

    static func make(
        from session: WorkoutSession,
        progressData: [ExerciseProgress],
        previousSession: WorkoutSession? = nil
    ) -> WorkoutShareSnapshot {
        let completedSets = session.sets.filter { $0.isCompleted }
        let duration = session.endTime?.timeIntervalSince(session.date) ?? 0

        var grouped: [String: [WorkoutSet]] = [:]
        for s in completedSets {
            grouped[s.exerciseName, default: []].append(s)
        }

        let progressByName = Dictionary(uniqueKeysWithValues: progressData.map { ($0.exerciseName, $0.progressState) })

        // Previous best weight per exercise from the prior session of this day.
        var prevBestByName: [String: Double] = [:]
        if let prev = previousSession {
            for s in prev.sets where s.isCompleted {
                let w = s.weight
                prevBestByName[s.exerciseName] = max(prevBestByName[s.exerciseName] ?? 0, w)
            }
        }

        // Best set per exercise = heaviest weight, ties broken by reps.
        let lines: [ExerciseLine] = grouped.map { name, sets in
            let best = sets.max(by: { lhs, rhs in
                if lhs.weight == rhs.weight { return lhs.reps < rhs.reps }
                return lhs.weight < rhs.weight
            })
            return ExerciseLine(
                name: name,
                bestWeight: best?.weight ?? 0,
                bestReps: best?.reps ?? 0,
                totalSets: sets.count,
                progress: progressByName[name],
                previousBestWeight: prevBestByName[name]
            )
        }
        // Sort: PRs first, then by volume contribution
        .sorted { lhs, rhs in
            let lImproved = lhs.progress == .improved ? 1 : 0
            let rImproved = rhs.progress == .improved ? 1 : 0
            if lImproved != rImproved { return lImproved > rImproved }
            return (lhs.bestWeight * Double(lhs.bestReps)) > (rhs.bestWeight * Double(rhs.bestReps))
        }

        let totalVolume = completedSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        let totalReps = completedSets.reduce(0) { $0 + $1.reps }
        let records = progressData.filter { $0.progressState == .improved }.count

        let prevVolume: Double? = previousSession.map { prev in
            prev.sets
                .filter { $0.isCompleted }
                .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        }

        return WorkoutShareSnapshot(
            workoutDayName: session.workoutDayName,
            programName: session.programName,
            date: session.date,
            durationSeconds: duration,
            totalVolumeKg: totalVolume,
            previousTotalVolumeKg: prevVolume,
            totalSets: completedSets.count,
            totalReps: totalReps,
            calories: session.calories ?? 0,
            averageHeartRate: session.averageHeartRate ?? 0,
            recordsCount: records,
            exercises: lines
        )
    }
}

// MARK: - Render canvas (9:16 — fills Instagram Stories edge-to-edge)

struct WorkoutShareRender: View {
    let snapshot: WorkoutShareSnapshot

    static let canvasWidth: CGFloat = 1080
    static let canvasHeight: CGFloat = 1920

    private let neon = DesignSystem.Colors.neonGreen

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer(minLength: 80)

                brandHeader

                Spacer(minLength: 40)

                heroBlock
                    .padding(.horizontal, 64)

                if snapshot.volumeDeltaPercent != nil {
                    Spacer(minLength: 32)
                    volumeDeltaHero
                        .padding(.horizontal, 64)
                }

                Spacer(minLength: 40)

                statsGrid
                    .padding(.horizontal, 56)

                if snapshot.recordsCount > 0 {
                    Spacer(minLength: 28)
                    recordsBadge
                        .padding(.horizontal, 56)
                }

                Spacer(minLength: 40)

                if !snapshot.exercises.isEmpty {
                    exercisesBlock
                        .padding(.horizontal, 56)
                }

                Spacer(minLength: 40)

                footer
                    .padding(.bottom, 80)
            }
        }
        .frame(width: Self.canvasWidth, height: Self.canvasHeight)
    }

    // MARK: Background
    private var background: some View {
        ZStack {
            Color.black

            Image("LaunchScreen")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 14)
                .opacity(0.30)
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
                .fill(neon)
                .frame(width: 900, height: 900)
                .blur(radius: 260)
                .offset(x: 260, y: -520)
                .opacity(0.22)

            Circle()
                .fill(Color.cyan)
                .frame(width: 600, height: 600)
                .blur(radius: 240)
                .offset(x: -260, y: 640)
                .opacity(0.14)
        }
    }

    // MARK: Brand header
    private var brandHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [neon.opacity(0.45), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 260, height: 260)
                    .blur(radius: 28)

                Image("BrandLogo")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: neon.opacity(0.55), radius: 28)
                    .shadow(color: .black.opacity(0.55), radius: 22, x: 0, y: 12)
            }

            Text("BODY FORGE")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .tracking(11)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: neon.opacity(0.25), radius: 14)

            HStack(spacing: 14) {
                Rectangle().fill(neon.opacity(0.55)).frame(width: 32, height: 1)
                Text("FORGE YOUR BODY")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(5)
                    .foregroundColor(neon.opacity(0.9))
                Rectangle().fill(neon.opacity(0.55)).frame(width: 32, height: 1)
            }
        }
    }

    // MARK: Hero
    private var heroBlock: some View {
        VStack(spacing: 14) {
            Text("ТРЕНИРОВКА ЗАВЕРШЕНА".localized())
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .tracking(7)
                .foregroundColor(neon)

            Text(snapshot.workoutDayName)
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            HStack(spacing: 12) {
                if let program = snapshot.programName, !program.isEmpty {
                    Text(program)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    Circle().fill(Color.white.opacity(0.3)).frame(width: 4, height: 4)
                }
                Text(formattedDate)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Volume delta hero — % change vs previous session
    private var volumeDeltaHero: some View {
        // We only render this when volumeDeltaPercent is non-nil.
        let pct = snapshot.volumeDeltaPercent ?? 0
        let isUp = pct > 0
        let isFlat = pct == 0
        let tint: Color = isUp
            ? Color(red: 0.30, green: 0.95, blue: 0.45)
            : (isFlat ? .white : Color(red: 1.0, green: 0.42, blue: 0.42))
        let icon = isUp
            ? "arrow.up.right"
            : (isFlat ? "equal" : "arrow.down.right")
        let title = isUp
            ? "ЛУЧШЕ ПРОШЛОЙ".localized()
            : (isFlat ? "СТАБИЛЬНО".localized() : "ОТ ПРОШЛОЙ".localized())
        let valueText = isUp ? "+\(pct)%" : (isFlat ? "0%" : "\(pct)%")

        return HStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.22))
                    .frame(width: 88, height: 88)
                Circle()
                    .stroke(tint.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(tint)
                    .shadow(color: tint.opacity(0.55), radius: 14)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(2.4)
                    .foregroundColor(.white.opacity(0.7))
                Text(valueText)
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: tint.opacity(0.45), radius: 16)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.18), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(tint.opacity(0.40), lineWidth: 1.2)
            }
        )
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.currentLocale
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: snapshot.date)
    }

    // MARK: Stats
    private var statsGrid: some View {
        VStack(spacing: 18) {
            HStack(spacing: 18) {
                statTile(
                    icon: "clock.fill",
                    tint: Color(red: 0.45, green: 0.85, blue: 1.0),
                    title: "Время".localized().uppercased(),
                    value: durationLabel,
                    unit: nil
                )
                statTile(
                    icon: "scalemass.fill",
                    tint: neon,
                    title: "Объём".localized().uppercased(),
                    value: volumeLabel.value,
                    unit: volumeLabel.unit
                )
            }
            HStack(spacing: 18) {
                statTile(
                    icon: "flame.fill",
                    tint: .orange,
                    title: "ккал".localized().uppercased(),
                    value: snapshot.calories > 0 ? "\(snapshot.calories)" : "—",
                    unit: nil
                )
                statTile(
                    icon: "list.bullet",
                    tint: Color(red: 0.85, green: 0.65, blue: 1.0),
                    title: "Подходов".localized().uppercased(),
                    value: "\(snapshot.totalSets)",
                    unit: snapshot.totalReps > 0 ? String(format: "%d %@".localized(), snapshot.totalReps, "повт.".localized()) : nil
                )
            }
        }
    }

    private func statTile(icon: String, tint: Color, title: String, value: String, unit: String?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.05))
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.18), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(tint)
                    Text(title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(2.5)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
                Text(value)
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let unit = unit {
                    Text(unit)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(28)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }

    private var durationLabel: String {
        let total = Int(snapshot.durationSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return m == 0
                ? String(format: "%dч".localized(), h)
                : String(format: "%dч %dм".localized(), h, m)
        }
        return String(format: "%dм".localized(), max(m, 0))
    }

    private var volumeLabel: (value: String, unit: String?) {
        if snapshot.totalVolumeKg >= 1000 {
            return (String(format: "%.1f", snapshot.totalVolumeKg / 1000), "т".localized())
        }
        return ("\(Int(snapshot.totalVolumeKg))", "кг".localized())
    }

    // MARK: Records badge — headline + top PR exercise names
    private var recordsBadge: some View {
        let topPRs = snapshot.exercises
            .filter { $0.progress == .improved }
            .prefix(3)
            .map { $0.name }
        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(neon)
                    .shadow(color: neon.opacity(0.6), radius: 12)
                Text(String(format: "%d %@".localized(), snapshot.recordsCount, "новых рекордов".localized()))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            if !topPRs.isEmpty {
                Text(topPRs.joined(separator: " · "))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 32)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(neon.opacity(0.16))
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(neon.opacity(0.55), lineWidth: 1.2)
            }
        )
        .shadow(color: neon.opacity(0.35), radius: 22)
    }

    // MARK: Exercises
    private var exercisesBlock: some View {
        let visible = Array(snapshot.exercises.prefix(6))
        let extras = max(0, snapshot.exercises.count - visible.count)
        return VStack(alignment: .leading, spacing: 14) {
            Text("УПРАЖНЕНИЯ".localized())
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundColor(.white.opacity(0.6))
                .padding(.leading, 4)

            VStack(spacing: 12) {
                ForEach(visible) { line in
                    exerciseRow(line)
                }
                if extras > 0 {
                    Text(String(format: "и ещё +%d".localized(), extras))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.top, 4)
                }
            }
        }
    }

    private func exerciseRow(_ line: WorkoutShareSnapshot.ExerciseLine) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(line.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(bestSetSummary(line))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }
            Spacer(minLength: 8)

            // Per-exercise % delta — only show when meaningful.
            if let pct = perExerciseDeltaPercent(line) {
                exerciseDeltaChip(pct: pct, isPR: line.progress == .improved)
            }

            Text(String(format: "×%d".localized(), line.totalSets))
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            if let p = line.progress {
                Image(systemName: p.icon)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(p.color)
                    .padding(9)
                    .background(Circle().fill(p.color.opacity(0.18)))
                    .overlay(Circle().stroke(p.color.opacity(0.5), lineWidth: 1))
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 22)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(line.progress == .improved
                          ? neon.opacity(0.10)
                          : Color.white.opacity(0.05))
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        line.progress == .improved
                            ? neon.opacity(0.45)
                            : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            }
        )
    }

    /// % change of best weight vs previous session for this exercise. Returns
    /// nil when there's no previous data, current weight is 0, or the change
    /// rounds to 0%.
    private func perExerciseDeltaPercent(_ line: WorkoutShareSnapshot.ExerciseLine) -> Int? {
        guard let prev = line.previousBestWeight, prev > 0, line.bestWeight > 0 else { return nil }
        let pct = Int(((line.bestWeight - prev) / prev * 100).rounded())
        return pct == 0 ? nil : pct
    }

    private func exerciseDeltaChip(pct: Int, isPR: Bool) -> some View {
        let tint: Color = pct > 0
            ? (isPR ? neon : Color(red: 0.30, green: 0.95, blue: 0.45))
            : Color(red: 1.0, green: 0.42, blue: 0.42)
        let label = pct > 0 ? "+\(pct)%" : "\(pct)%"
        return Text(label)
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .foregroundColor(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                ZStack {
                    Capsule().fill(tint.opacity(0.18))
                    Capsule().stroke(tint.opacity(0.45), lineWidth: 0.8)
                }
            )
    }

    private func bestSetSummary(_ line: WorkoutShareSnapshot.ExerciseLine) -> String {
        if line.bestWeight > 0 && line.bestReps > 0 {
            let weight = line.bestWeight.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%d", Int(line.bestWeight))
                : String(format: "%.1f", line.bestWeight)
            return String(format: "%@ %@ × %d".localized(), weight, "кг".localized(), line.bestReps)
        }
        if line.bestReps > 0 {
            return String(format: "%d %@".localized(), line.bestReps, "повт.".localized())
        }
        return ""
    }

    // MARK: Footer
    private var footer: some View {
        VStack(spacing: 8) {
            Text("Body Forge — твоя личная кузница тела".localized())
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1.5)
        }
    }
}

// MARK: - Share sheet wrapper

struct WorkoutSharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct WorkoutShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// Wrapping UIActivityViewController in SwiftUI's `.sheet` is broken on iPad:
// any share action that pushes a sub-sheet (Mail, Save to Drive, sign-in flow)
// collapses the parent SwiftUI sheet and dumps the user back to whatever was
// underneath. Presenting the activity controller straight from UIKit also lets
// us configure the popover anchor that iPad requires, so use this helper from
// every share button instead of `.sheet(item:)`.
@MainActor
enum ShareSheetPresenter {
    static func present(items: [Any]) {
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              let root = window.rootViewController else { return }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }

        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = vc.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(
                x: top.view.bounds.midX,
                y: top.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        top.present(vc, animated: true)
    }
}

// MARK: - Renderer helper

@MainActor
enum WorkoutShareRenderer {
    static func makeImage(snapshot: WorkoutShareSnapshot) -> UIImage? {
        let card = WorkoutShareRender(snapshot: snapshot)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = .init(
            width: WorkoutShareRender.canvasWidth,
            height: WorkoutShareRender.canvasHeight
        )
        return renderer.uiImage
    }
}
