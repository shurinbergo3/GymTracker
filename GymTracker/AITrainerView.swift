//
//  AITrainerView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct AITrainerView: View {
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated Background Gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.0, blue: 0.2) // Deep purple tint
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        
                        // Hero Section
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [DesignSystem.Colors.neonGreen.opacity(0.3), .clear],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 80
                                        )
                                    )
                                    .frame(width: 140, height: 140)
                                    .blur(radius: 15)
                                
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 60))
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                                    .shadow(color: DesignSystem.Colors.neonGreen, radius: 15, x: 0, y: 0)
                            }
                            
                            Text("AI Тренер")
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("Ваш персональный аналитик")
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .padding(.top, 20)
                        
                        // Feature Grid
                        VStack(spacing: DesignSystem.Spacing.md) {
                            AIFeatureRow(
                                icon: "chart.xyaxis.line",
                                title: "Анализ тренировок",
                                description: "AI анализирует ваши показатели и подсказывает, где вы можете улучшиться."
                            )
                            
                            AIFeatureRow(
                                icon: "message.fill",
                                title: "Умный чат",
                                description: "Спрашивает о самочувствии и корректирует нагрузку в реальном времени."
                            )
                            
                            AIFeatureRow(
                                icon: "list.clipboard.fill",
                                title: "Персональная программа",
                                description: "Создает план тренировок, идеально подходящий под ваши цели."
                            )
                            
                            AIFeatureRow(
                                icon: "cross.case.fill",
                                title: "Мониторинг анализов",
                                description: "Загрузите результаты анализов, и AI даст рекомендации по питанию и бадам."
                            )
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        Spacer()
                        
                        // CTA Button
                        GradientButton(title: "Активировать (Скоро)", icon: "sparkles") {
                            // Action placeholder
                        }
                        .opacity(0.8) // Showing it's coming soon
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.bottom, DesignSystem.Spacing.lg)
                    }
                    .frame(minHeight: UIScreen.main.bounds.height - 150) // Ensure it fills space but doesn't force scroll if not needed
                }
            }
            .navigationTitle("AI Тренер")
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

struct AIFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(DesignSystem.Colors.neonGreen)
                .frame(width: 50, height: 50)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignSystem.Colors.neonGreen.opacity(0.3), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(DesignSystem.Typography.subheadline())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

#Preview {
    AITrainerView()
}
