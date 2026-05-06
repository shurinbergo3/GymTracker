//
//  AITrainerView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct AITrainerView: View {
    @State private var showingSettings = false
    @State private var showingDevAlert = false // Alert state

    var body: some View {
        NavigationStack {
            ZStack {
                // OLED Black Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                // Subtle top gradient for depth
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.cardBackground.opacity(0.8),
                        DesignSystem.Colors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .frame(height: 300)
                .position(x: UIScreen.main.bounds.width / 2, y: 0)
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    
                    // Hero Section
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [DesignSystem.Colors.neonGreen.opacity(0.2), .clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .blur(radius: 10)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 48))
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                                .shadow(color: DesignSystem.Colors.neonGreen, radius: 10, x: 0, y: 0)
                        }
                        
                        Text("AI Coach".localized())
                            .font(DesignSystem.Typography.title())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Your Personal Analyst".localized())
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Feature Grid
                    ScrollView {
                        VStack(spacing: 12) {
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
                    }
                    
                    Spacer()
                    
                    // CTA Button
                    GradientButton(title: "Активировать (Скоро)".localized(), icon: "sparkles") {
                        showingDevAlert = true
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("AI Coach".localized())
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
            // The requested "Success" alert/window
            .alert("В разработке".localized(), isPresented: $showingDevAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Этот функционал еще создается. Скоро будет доступно!".localized())
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
