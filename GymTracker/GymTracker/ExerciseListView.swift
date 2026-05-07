//
//  ExerciseListView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct ExerciseListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ExerciseListViewModel()
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            exerciseList
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Поиск упражнений".localized()
        )
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.search()
        }
        .navigationTitle("Упражнения".localized())
        .navigationBarTitleDisplayMode(.large)
        .id(languageManager.refreshID)
    }

    @ViewBuilder
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    exerciseSection(for: category)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }

    @ViewBuilder
    private func exerciseSection(for category: ExerciseCategory) -> some View {
        if let exercises = viewModel.groups[category], !exercises.isEmpty {
            Section {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(exercises) { exercise in
                        ExerciseListRow(exercise: exercise, accent: category.accentColor)
                    }
                }
                .padding(.top, DesignSystem.Spacing.xs)
            } header: {
                CategorySectionHeader(category: category, count: exercises.count)
            }
        }
    }
}

// MARK: - Vibrant Category Header (sticky)

private struct CategorySectionHeader: View {
    let category: ExerciseCategory
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            // Icon orb with gradient + glow
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [category.accentColor, category.accentColorSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: category.accentColor.opacity(0.45), radius: 10, x: 0, y: 4)

                Image(systemName: category.icon)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.black.opacity(0.85))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Text("\(count) \("упражнений".localized())")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(category.accentColor)
                    .textCase(.uppercase)
                    .tracking(0.6)
            }

            Spacer()

            // Count badge
            Text("\(count)")
                .font(.system(.callout, design: .rounded, weight: .heavy))
                .foregroundColor(.black)
                .frame(minWidth: 36, minHeight: 28)
                .padding(.horizontal, 10)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [category.accentColor, category.accentColorSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                )
                .shadow(color: category.accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            ZStack {
                // Solid base so list rows don't show through during scroll
                DesignSystem.Colors.background
                // Subtle gradient tint
                LinearGradient(
                    colors: [
                        category.accentColor.opacity(0.18),
                        category.accentColor.opacity(0.04)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
                .padding(.horizontal, 4)
            }
        )
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [category.accentColor.opacity(0.5), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            .padding(.horizontal, 12)
        }
    }
}

// MARK: - Colorful Row

struct ExerciseListRow: View {
    let exercise: LibraryExercise
    let accent: Color
    @State private var showingTechnique = false
    @Environment(\.openURL) var openURL

    var body: some View {
        HStack(spacing: 14) {
            // Vertical accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4, height: 44)

            // Title + muscle chip
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name.localized())
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5, weight: .bold))
                        .foregroundColor(accent)
                    Text(exercise.muscleGroup.rawValue)
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundColor(accent)
                        .tracking(0.4)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(accent.opacity(0.15))
                )
                .overlay(
                    Capsule().stroke(accent.opacity(0.3), lineWidth: 0.7)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { showingTechnique = true }

            // YouTube launcher
            if let url = youtubeSearchURL(for: exercise.name) {
                Button {
                    openURL(url)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.20, blue: 0.20),
                                        Color(red: 0.85, green: 0.05, blue: 0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 32)
                            .shadow(color: Color.red.opacity(0.45), radius: 6, x: 0, y: 3)

                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Info chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(accent.opacity(0.7))
                .contentShape(Rectangle())
                .onTapGesture { showingTechnique = true }
        }
        .padding(.vertical, DesignSystem.Spacing.sm + 2)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.10),
                            DesignSystem.Colors.cardBackground
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.15), radius: 8, x: 0, y: 3)
        .sheet(isPresented: $showingTechnique) {
            ExerciseTechniqueDetailView(exerciseName: exercise.name)
        }
    }
}

// MARK: - Localized YouTube search

private func youtubeSearchURL(for exerciseName: String) -> URL? {
    let localizedName = exerciseName.localized()
    let suffix = LanguageManager.shared.currentLanguageCode == "en" ? "technique" : "техника"
    let searchQuery = "\(localizedName) \(suffix)"
    let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    return URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)")
}

#Preview {
    NavigationStack {
        ExerciseListView()
    }
}
