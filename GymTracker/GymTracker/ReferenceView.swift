//
//  ReferenceView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct ReferenceView: View {
    @State private var showingSettings = false

    private var exerciseCount: Int { ExerciseLibrary.allExercises.count }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {

                        // Header
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("База знаний для твоего прогресса".localized())
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.lg)

                        // Hero card — Exercises (full width)
                        NavigationLink(destination: ExerciseListView()) {
                            ReferenceHeroCard(
                                title: "Упражнения".localized(),
                                subtitle: "Technique and Description".localized(),
                                exerciseCount: exerciseCount,
                                icon: "dumbbell.fill",
                                accent: DesignSystem.Colors.neonGreen
                            )
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)

                        // Bento grid for the remaining cards
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: DesignSystem.Spacing.md), GridItem(.flexible(), spacing: DesignSystem.Spacing.md)], spacing: DesignSystem.Spacing.md) {

                            NavigationLink(destination: WorkoutGuideView()) {
                                ReferenceBentoCard(
                                    title: "Тренировки".localized(),
                                    subtitle: "Training Guide".localized(),
                                    icon: "figure.strengthtraining.traditional",
                                    color: DesignSystem.Colors.accentPurple,
                                    height: 160
                                )
                            }

                            NavigationLink(destination: SupplementsView()) {
                                ReferenceBentoCard(
                                    title: "Бады".localized(),
                                    subtitle: "Top Supplements".localized(),
                                    icon: "pills.fill",
                                    color: .blue,
                                    height: 160
                                )
                            }

                            NavigationLink(destination: HormonesView()) {
                                ReferenceBentoCard(
                                    title: "Гормоны".localized(),
                                    subtitle: "Impact on Life".localized(),
                                    icon: "bolt.heart.fill",
                                    color: .pink,
                                    height: 160
                                )
                            }

                            NavigationLink(destination: SleepGuideView()) {
                                ReferenceBentoCard(
                                    title: "Сон".localized(),
                                    subtitle: "Recovery".localized(),
                                    icon: "moon.stars.fill",
                                    color: .indigo,
                                    height: 160
                                )
                            }

                            NavigationLink(destination: NutritionGuideView()) {
                                ReferenceBentoCard(
                                    title: "Питание".localized(),
                                    subtitle: "Fuel for the Body".localized(),
                                    icon: "fork.knife",
                                    color: .orange,
                                    height: 160
                                )
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.bottom, DesignSystem.Spacing.xl)
                    }
                }
            }
            .navigationTitle("Справочник".localized())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    UserProfileButton {
                        showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Hero card

struct ReferenceHeroCard: View {
    let title: String
    let subtitle: String
    let exerciseCount: Int
    let icon: String
    let accent: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Layered gradient background
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.22),
                            DesignSystem.Colors.cardBackground,
                            DesignSystem.Colors.cardBackground
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .stroke(accent.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 8)

            // Decorative oversized icon
            Image(systemName: icon)
                .font(.system(size: 130, weight: .bold))
                .foregroundColor(accent.opacity(0.10))
                .rotationEffect(.degrees(-12))
                .offset(x: 180, y: 30)
                .clipped()

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(accent)
                        .font(.caption)
                    Text("Library".localized())
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(accent)
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(accent.opacity(0.15))
                )

                Spacer(minLength: 0)

                Text(title)
                    .font(DesignSystem.Typography.title())
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text(subtitle)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.secondaryText)

                HStack(spacing: 14) {
                    HeroStatChip(value: "\(exerciseCount)", label: "Упражнений".localized())
                    HeroStatChip(value: "9", label: "Категорий".localized())
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(accent)
                        .padding(10)
                        .background(Circle().fill(accent.opacity(0.15)))
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .frame(height: 220)
    }
}

private struct HeroStatChip: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundColor(DesignSystem.Colors.primaryText)
            Text(label)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .textCase(.uppercase)
        }
    }
}

// MARK: - Bento card

struct ReferenceBentoCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let height: CGFloat
    var isDisabled: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background gradient
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.18),
                            DesignSystem.Colors.cardBackground
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .stroke(color.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)

            // Decorative icon
            Image(systemName: icon)
                .font(.system(size: 70, weight: .bold))
                .foregroundColor(isDisabled ? DesignSystem.Colors.secondaryText : color.opacity(0.18))
                .rotationEffect(.degrees(15))
                .offset(x: 60, y: -10)
                .clipped()

            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isDisabled ? Color.white.opacity(0.06) : color.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isDisabled ? DesignSystem.Colors.secondaryText : color)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(DesignSystem.Typography.title3())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(isDisabled ? DesignSystem.Colors.secondaryText : color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(isDisabled ? Color.clear : color.opacity(0.15))
                        )
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .frame(height: height)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

#Preview {
    ReferenceView()
}
