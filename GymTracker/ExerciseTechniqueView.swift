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
        ExerciseLibrary.getTechnique(for: exerciseName)
    }
    
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

// MARK: - Technique Detail View

// MARK: - Technique Detail View

struct ExerciseTechniqueDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let exerciseName: String
    
    // Fetch full exercise object for metadata
    private var exercise: LibraryExercise? {
        ExerciseLibrary.getExercise(for: exerciseName)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 1. Title & Type
                        VStack(alignment: .leading, spacing: 12) {
                            Text(exerciseName)
                                .font(.system(size: 32, weight: .bold)) // Large Title
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            
                            // Category / Type Tag
                            if let exercise = exercise {
                                HStack(spacing: 8) {
                                    Image(systemName: exercise.category.icon)
                                        .foregroundColor(DesignSystem.Colors.neonGreen)
                                    Text(exercise.category.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(DesignSystem.Colors.neonGreen)
                                    
                                    Text("•")
                                        .foregroundColor(.gray)
                                    
                                    Text(exercise.muscleGroup.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(DesignSystem.Colors.cardBackground)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 2. Technique Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.title3)
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                                Text("Техника выполнения")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            if let text = exercise?.technique {
                                Text(text)
                                    .font(.body)
                                    .foregroundColor(Color.white.opacity(0.85))
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("Описание техники пока недоступно для этого упражнения.")
                                    .font(.body)
                                    .italic()
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(24)
                        .background(DesignSystem.Colors.cardBackground) // Use the dark card background
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 20)
                        
                        // 3. YouTube Button
                        if let youtubeUrl = youtubeSearchURL(for: exerciseName) {
                            Link(destination: youtubeUrl) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                    Text("Смотреть на YouTube")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.footnote)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.red, Color(red: 0.8, green: 0, blue: 0)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Гайд упражнения")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(Color(UIColor.systemGray2))
                    }
                }
            }
        }
    }
    
    private func youtubeSearchURL(for exerciseName: String) -> URL? {
        let searchQuery = "\(exerciseName) техника выполнения"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)")
    }
}

#Preview {
    ExerciseTechniqueDetailView(
        exerciseName: "Приседания со штангой"
    )
}
