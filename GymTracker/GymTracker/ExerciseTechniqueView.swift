//
//  ExerciseTechniqueView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI

// MARK: - Exercise Info Button

struct ExerciseInfoButton: View {
    let exerciseName: String
    @State private var showingTechnique = false

    var body: some View {
        Button(action: { showingTechnique = true }) {
            Image(systemName: "info.circle")
                .foregroundColor(DesignSystem.Colors.accent)
                .font(.system(size: 16))
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingTechnique) {
            ExerciseTechniqueDetailView(exerciseName: exerciseName)
        }
    }
}

// MARK: - Technique Section Model

private struct TechniqueSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let icon: String
    let color: Color
}

private enum TechniqueParser {
    /// Parses a structured technique string into labelled sections.
    /// Recognised prefixes: "Старт:", "Движение:", "Ключи:". Unmatched prose
    /// becomes a generic "Описание" section.
    static func parse(_ text: String) -> [TechniqueSection] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // Split by double newlines or label boundaries
        let labels: [(label: String, title: String, icon: String, color: Color)] = [
            ("Старт:",    "Стартовое положение".localized(), "figure.stand",        DesignSystem.Colors.neonGreen),
            ("Движение:", "Движение".localized(),            "arrow.up.arrow.down", .orange),
            ("Ключи:",    "Ключевые моменты".localized(),    "key.fill",            .yellow),
        ]

        var sections: [TechniqueSection] = []
        var leftover = trimmed

        // Greedy multi-pass: each pass tries to peel off the next labelled chunk.
        // Search for any label inside `leftover`; the section continues until the next label or end.
        while !leftover.isEmpty {
            // Find earliest label position
            var earliestIdx: String.Index?
            var matchedSpec: (label: String, title: String, icon: String, color: Color)?
            for spec in labels {
                if let r = leftover.range(of: spec.label) {
                    if earliestIdx == nil || r.lowerBound < earliestIdx! {
                        earliestIdx = r.lowerBound
                        matchedSpec = spec
                    }
                }
            }

            if let idx = earliestIdx, let spec = matchedSpec {
                // Anything before the first label is a generic preamble
                let preamble = String(leftover[..<idx]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !preamble.isEmpty {
                    sections.append(TechniqueSection(
                        title: "Описание".localized(),
                        body: preamble,
                        icon: "text.alignleft",
                        color: DesignSystem.Colors.accent
                    ))
                }

                // Compute body of this section: from end-of-label to next label or end
                let labelEnd = leftover.index(idx, offsetBy: spec.label.count)
                var sectionEnd = leftover.endIndex
                for next in labels where next.label != spec.label {
                    if let r = leftover.range(of: next.label, range: labelEnd..<leftover.endIndex) {
                        if r.lowerBound < sectionEnd {
                            sectionEnd = r.lowerBound
                        }
                    }
                }
                let body = String(leftover[labelEnd..<sectionEnd])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !body.isEmpty {
                    sections.append(TechniqueSection(
                        title: spec.title,
                        body: body,
                        icon: spec.icon,
                        color: spec.color
                    ))
                }
                leftover = String(leftover[sectionEnd...])
            } else {
                // No labels left; the rest is generic prose
                let rest = leftover.trimmingCharacters(in: .whitespacesAndNewlines)
                if !rest.isEmpty {
                    sections.append(TechniqueSection(
                        title: "Описание".localized(),
                        body: rest,
                        icon: "text.alignleft",
                        color: DesignSystem.Colors.accent
                    ))
                }
                break
            }
        }

        return sections
    }
}

// MARK: - Technique Detail View

struct ExerciseTechniqueDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let exerciseName: String

    private var exercise: LibraryExercise? {
        ExerciseLibrary.getExercise(for: exerciseName)
    }

    private var sections: [TechniqueSection] {
        guard let raw = exercise?.technique?.localized(), !raw.isEmpty else { return [] }
        return TechniqueParser.parse(raw)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerCard
                        techniqueSections
                        Spacer(minLength: 12)
                        youtubeButton
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Гайд упражнения".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(action: { dismiss() })
                }
            }
        }
    }

    // MARK: Header

    @ViewBuilder
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(exerciseName.localized())
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .minimumScaleFactor(0.8)

            if let exercise = exercise {
                HStack(spacing: 8) {
                    TagPill(
                        icon: exercise.category.icon,
                        text: exercise.category.rawValue,
                        accent: DesignSystem.Colors.neonGreen
                    )
                    TagPill(
                        icon: "scope",
                        text: exercise.muscleGroup.rawValue,
                        accent: DesignSystem.Colors.accentMint
                    )
                    TagPill(
                        icon: exercise.defaultType.icon,
                        text: exercise.defaultType.displayName,
                        accent: .orange
                    )
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: Technique sections

    @ViewBuilder
    private var techniqueSections: some View {
        if sections.isEmpty {
            // Fallback when no structured technique is available
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Техника выполнения".localized(),
                              icon: "lightbulb.fill",
                              color: DesignSystem.Colors.neonGreen)
                Text("Описание техники пока недоступно для этого упражнения.".localized())
                    .font(.body)
                    .italic()
                    .foregroundColor(.gray)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(20)
            .padding(.horizontal, 16)
        } else {
            VStack(spacing: 14) {
                ForEach(sections) { section in
                    TechniqueCard(section: section)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: YouTube button

    @ViewBuilder
    private var youtubeButton: some View {
        Button(action: openVideo) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                Text("Смотреть на YouTube".localized())
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.footnote)
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.red, Color(red: 0.8, green: 0.0, blue: 0.0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 16)
    }

    // MARK: Open video

    private func openVideo() {
        var urlString: String
        if let stored = exercise?.videoUrl, !stored.isEmpty {
            urlString = stored
        } else {
            let localizedName = exerciseName.localized()
            let suffix = LanguageManager.shared.currentLanguageCode == "en" ? "technique" : "техника выполнения"
            let searchQuery = "\(localizedName) \(suffix)"
            if let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                urlString = "https://www.youtube.com/results?search_query=\(encodedQuery)"
            } else {
                return
            }
        }

        // SECURITY: only http(s) YouTube hosts allowed
        guard let parsed = URL(string: urlString),
              let scheme = parsed.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = parsed.host?.lowercased(),
              host == "youtube.com" || host == "www.youtube.com" || host == "m.youtube.com" || host == "youtu.be" else {
            #if DEBUG
            print("⚠️ openVideo: rejected non-YouTube URL \(urlString)")
            #endif
            return
        }

        let appUrlString = urlString
            .replacingOccurrences(of: "https://", with: "youtube://")
            .replacingOccurrences(of: "http://", with: "youtube://")

        if let appUrl = URL(string: appUrlString), UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
            return
        }

        var webUrlString = urlString
        if webUrlString.contains("www.youtube.com") {
            webUrlString = webUrlString.replacingOccurrences(of: "www.youtube.com", with: "m.youtube.com")
        }

        if let webUrl = URL(string: webUrlString) {
            UIApplication.shared.open(webUrl)
        }
    }
}

// MARK: - Subviews

private struct TagPill: View {
    let icon: String
    let text: String
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .foregroundColor(accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(accent.opacity(0.15))
        )
        .overlay(
            Capsule().stroke(accent.opacity(0.25), lineWidth: 1)
        )
    }
}

private struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

private struct TechniqueCard: View {
    let section: TechniqueSection

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: section.title, icon: section.icon, color: section.color)

            Text(section.body)
                .font(.body)
                .foregroundColor(Color.white.opacity(0.88))
                .lineSpacing(6)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(section.color.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    ExerciseTechniqueDetailView(exerciseName: "Приседания со штангой")
}
