//
//  WorkoutShareCard.swift
//  GymTracker
//
//  4:5 (1080×1350) share render of a finished workout: brand mark on top,
//  hero stats, PR badge and per-exercise breakdown. Rendered offscreen via
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
    }

    let workoutDayName: String
    let programName: String?
    let date: Date
    let durationSeconds: TimeInterval
    let totalVolumeKg: Double
    let totalSets: Int
    let totalReps: Int
    let calories: Int
    let averageHeartRate: Int
    let recordsCount: Int
    let exercises: [ExerciseLine]

    static func make(
        from session: WorkoutSession,
        progressData: [ExerciseProgress]
    ) -> WorkoutShareSnapshot {
        let completedSets = session.sets.filter { $0.isCompleted }
        let duration = session.endTime?.timeIntervalSince(session.date) ?? 0

        var grouped: [String: [WorkoutSet]] = [:]
        for s in completedSets {
            grouped[s.exerciseName, default: []].append(s)
        }

        let progressByName = Dictionary(uniqueKeysWithValues: progressData.map { ($0.exerciseName, $0.progressState) })

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
                progress: progressByName[name]
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

        return WorkoutShareSnapshot(
            workoutDayName: session.workoutDayName,
            programName: session.programName,
            date: session.date,
            durationSeconds: duration,
            totalVolumeKg: totalVolume,
            totalSets: completedSets.count,
            totalReps: totalReps,
            calories: session.calories ?? 0,
            averageHeartRate: session.averageHeartRate ?? 0,
            recordsCount: records,
            exercises: lines
        )
    }
}

// MARK: - Render canvas (4:5)

struct WorkoutShareRender: View {
    let snapshot: WorkoutShareSnapshot

    static let canvasWidth: CGFloat = 1080
    static let canvasHeight: CGFloat = 1350

    private let neon = DesignSystem.Colors.neonGreen

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                brandHeader
                    .padding(.top, 64)

                Spacer(minLength: 24)

                heroBlock
                    .padding(.horizontal, 64)

                Spacer(minLength: 28)

                statsGrid
                    .padding(.horizontal, 56)

                if snapshot.recordsCount > 0 {
                    recordsBadge
                        .padding(.top, 28)
                }

                Spacer(minLength: 28)

                if !snapshot.exercises.isEmpty {
                    exercisesBlock
                        .padding(.horizontal, 56)
                }

                Spacer(minLength: 24)

                footer
                    .padding(.bottom, 56)
            }
        }
        .frame(width: Self.canvasWidth, height: Self.canvasHeight)
    }

    // MARK: Background
    private var background: some View {
        ZStack {
            Color.black

            Circle()
                .fill(neon)
                .frame(width: 800, height: 800)
                .blur(radius: 240)
                .offset(x: 240, y: -380)
                .opacity(0.22)

            Circle()
                .fill(Color.cyan)
                .frame(width: 540, height: 540)
                .blur(radius: 220)
                .offset(x: -240, y: 460)
                .opacity(0.14)

            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: Brand header
    private var brandHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [neon.opacity(0.45), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 130
                        )
                    )
                    .frame(width: 220, height: 220)
                    .blur(radius: 24)

                Image("BrandLogo")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 116, height: 116)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: neon.opacity(0.55), radius: 24)
                    .shadow(color: .black.opacity(0.55), radius: 20, x: 0, y: 10)
            }

            Text("BODY FORGE")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .tracking(10)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: neon.opacity(0.25), radius: 12)

            HStack(spacing: 12) {
                Rectangle().fill(neon.opacity(0.55)).frame(width: 28, height: 1)
                Text("FORGE YOUR BODY")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(5)
                    .foregroundColor(neon.opacity(0.9))
                Rectangle().fill(neon.opacity(0.55)).frame(width: 28, height: 1)
            }
        }
    }

    // MARK: Hero
    private var heroBlock: some View {
        VStack(spacing: 12) {
            Text("ТРЕНИРОВКА ЗАВЕРШЕНА".localized())
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .tracking(6)
                .foregroundColor(neon)

            Text(snapshot.workoutDayName)
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            HStack(spacing: 10) {
                if let program = snapshot.programName, !program.isEmpty {
                    Text(program)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    Circle().fill(Color.white.opacity(0.3)).frame(width: 4, height: 4)
                }
                Text(formattedDate)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.currentLocale
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: snapshot.date)
    }

    // MARK: Stats
    private var statsGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
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
            HStack(spacing: 16) {
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

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(tint)
                    Text(title)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .tracking(2.5)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
                Text(value)
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let unit = unit {
                    Text(unit)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(24)
        }
        .frame(height: 200)
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

    // MARK: Records badge
    private var recordsBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(neon)
            Text(String(format: "%d %@".localized(), snapshot.recordsCount, "новых рекордов".localized()))
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(
            ZStack {
                Capsule().fill(neon.opacity(0.16))
                Capsule().stroke(neon.opacity(0.55), lineWidth: 1.2)
            }
        )
        .shadow(color: neon.opacity(0.35), radius: 18)
    }

    // MARK: Exercises
    private var exercisesBlock: some View {
        let visible = Array(snapshot.exercises.prefix(5))
        let extras = max(0, snapshot.exercises.count - visible.count)
        return VStack(alignment: .leading, spacing: 12) {
            Text("УПРАЖНЕНИЯ".localized())
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundColor(.white.opacity(0.6))
                .padding(.leading, 4)

            VStack(spacing: 10) {
                ForEach(visible) { line in
                    exerciseRow(line)
                }
                if extras > 0 {
                    Text(String(format: "и ещё +%d".localized(), extras))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.top, 2)
                }
            }
        }
    }

    private func exerciseRow(_ line: WorkoutShareSnapshot.ExerciseLine) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(line.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(bestSetSummary(line))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }
            Spacer(minLength: 8)

            Text(String(format: "×%d".localized(), line.totalSets))
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            if let p = line.progress {
                Image(systemName: p.icon)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(p.color)
                    .padding(8)
                    .background(Circle().fill(p.color.opacity(0.18)))
                    .overlay(Circle().stroke(p.color.opacity(0.5), lineWidth: 1))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
        VStack(spacing: 6) {
            Text("Body Forge — твоя личная кузница тела".localized())
                .font(.system(size: 14, weight: .semibold, design: .rounded))
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
