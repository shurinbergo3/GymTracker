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
                                        Image(systemName: "play.rectangle.fill")
                                            .foregroundColor(.red)
                                            .font(.title2)
                                        
                                        Text("Посмотреть технику на YouTube")
                                            .font(DesignSystem.Typography.headline())
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                    .padding(DesignSystem.Spacing.lg)
                                    .background(DesignSystem.Colors.cardBackground)
                                    .cornerRadius(DesignSystem.CornerRadius.large)
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
