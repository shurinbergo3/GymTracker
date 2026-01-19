//
//  ReferenceView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct ReferenceView: View {
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("База знаний для твоего прогресса")
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.lg)
                        
                        // Bento Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.md) {
                            
                            // 1. Exercises (Large Card - Full Width)
                            NavigationLink(destination: ExerciseListView()) {
                                ReferenceBentoCard(
                                    title: "Упражнения",
                                    subtitle: "Техника и описание",
                                    icon: "dumbbell.fill",
                                    color: DesignSystem.Colors.neonGreen,
                                    height: 180
                                )
                            }
                            .gridCellColumns(2) // Span across 2 columns
                            
                            // 2. Supplements (Medium Card)
                            NavigationLink(destination: WorkoutGuideView()) {
                    ReferenceBentoCard(
                        title: "Тренировки",
                        subtitle: "Гайд по тренингу",
                        icon: "dumbbell.fill",
                        color: .purple,
                        height: 160
                    )
                }
                
                NavigationLink(destination: SupplementsView()) {
                                ReferenceBentoCard(
                                    title: "Бады",
                                    subtitle: "Топовые добавки",
                                    icon: "pills.fill",
                                    color: .blue,
                                    height: 160
                                )
                            }
                            
                            // 3. Hormones (Medium Card)
                            NavigationLink(destination: HormonesView()) {
                                ReferenceBentoCard(
                                    title: "Гормоны",
                                    subtitle: "Влияние на жизнь",
                                    icon: "bolt.heart.fill",
                                    color: .purple,
                                    height: 160
                                )
                            }

                            // 4. Sleep (Medium Card)
                            NavigationLink(destination: SleepGuideView()) {
                                ReferenceBentoCard(
                                    title: "Сон",
                                    subtitle: "Восстановление",
                                    icon: "moon.stars.fill",
                                    color: .indigo,
                                    height: 160
                                )
                            }

                            // 4. Nutrition (Medium Card)
                            NavigationLink(destination: NutritionGuideView()) {
                                ReferenceBentoCard(
                                    title: "Питание",
                                    subtitle: "Топливо для тела",
                                    icon: "fork.knife",
                                    color: .orange,
                                    height: 160
                                )
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Справочник")
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

struct ReferenceBentoCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let height: CGFloat
    var isDisabled: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background with gradient
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Content
            VStack(alignment: .leading, spacing: 0) {
                // Icon Top Right
                HStack {
                    Spacer()
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundColor(isDisabled ? DesignSystem.Colors.secondaryText : color.opacity(0.8))
                        .rotationEffect(.degrees(15))
                        .offset(x: 10, y: -10)
                }
                
                Spacer()
                
                // Text Bottom Left
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DesignSystem.Typography.title3())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(isDisabled ? DesignSystem.Colors.secondaryText : color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isDisabled ? Color.clear : color.opacity(0.15))
                                .overlay(
                                    Capsule().stroke(isDisabled ? DesignSystem.Colors.secondaryText : Color.clear, lineWidth: 1)
                                )
                        )
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .frame(height: height)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

#Preview {
    ReferenceView()
}
