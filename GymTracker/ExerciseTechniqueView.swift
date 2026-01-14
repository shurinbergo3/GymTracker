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
    
    private var technique: String? {
        ExerciseLibrary.allExercises.first { $0.name == exerciseName }?.technique
    }
    
    var body: some View {
        Button(action: { showingTechnique = true }) {
            Image(systemName: "info.circle")
                .foregroundColor(DesignSystem.Colors.accent)
                .font(.system(size: 16))
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingTechnique) {
            ExerciseTechniqueDetailView(exerciseName: exerciseName, technique: technique)
        }
    }
}

// MARK: - Technique Detail View

struct ExerciseTechniqueDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let exerciseName: String
    let technique: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                        // Exercise Name
                        Text(exerciseName)
                            .font(DesignSystem.Typography.largeTitle())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        // Technique Description
                        if let technique = technique {
                            CardView {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    HStack {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(DesignSystem.Colors.neonGreen)
                                            .font(.title2)
                                        Text("Техника выполнения")
                                            .font(DesignSystem.Typography.title3())
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                    }
                                    
                                    Text(technique)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .lineSpacing(4)
                                }
                                .padding(DesignSystem.Spacing.xl)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            
                            // YouTube Button
                            if let youtubeUrl = youtubeSearchURL(for: exerciseName) {
                                Link(destination: youtubeUrl) {
                                    HStack(spacing: DesignSystem.Spacing.md) {
                                        Image(systemName: "play.fill")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.white.opacity(0.2))
                                            .clipShape(Circle())
                                        
                                        Text("Смотреть на YouTube")
                                            .font(DesignSystem.Typography.title3())
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.8, green: 0.0, blue: 0.0), Color(red: 0.6, green: 0.0, blue: 0.0)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(DesignSystem.CornerRadius.large)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .shadow(color: Color.red.opacity(0.4), radius: 12, x: 0, y: 6)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                            }
                        } else {
                            CardView {
                                VStack(spacing: DesignSystem.Spacing.md) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 48))
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                    
                                    Text("Описание техники пока недоступно")
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(DesignSystem.Spacing.xl)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Гайд упражнения")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                }
            }
        }
    }
    
    private func youtubeSearchURL(for exerciseName: String) -> URL? {
        // Создаем полный поисковый запрос и кодируем его целиком
        let searchQuery = "\(exerciseName) техника выполнения"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)")
    }
}

#Preview {
    ExerciseTechniqueDetailView(
        exerciseName: "Приседания со штангой",
        technique: "Штанга на трапециях. Отводи таз назад, колени смотрят в стороны (по носкам). Дави пятками в пол."
    )
}
