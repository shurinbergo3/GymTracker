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
                            Text(exerciseName.localized())
                                .font(.system(size: 28, weight: .bold)) // Slightly smaller for small screens
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil) // Allow multiline
                                .minimumScaleFactor(0.8) // Scale down if needed
                            
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
                        .padding(.horizontal, 16) // Reduced padding for small screens
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 2. Technique Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.title3)
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                                Text("Техника выполнения".localized())
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            if let text = exercise?.technique {
                                Text(text.localized())
                                    .font(.body)
                                    .foregroundColor(Color.white.opacity(0.85))
                                    .lineSpacing(6)
                                    .lineLimit(nil) // Allow unlimited lines
                            } else {
                                Text("Описание техники пока недоступно для этого упражнения.".localized())
                                    .font(.body)
                                    .italic()
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(20) // Reduced from 24
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(20)
                        .padding(.horizontal, 16) // Reduced from 20
                        
                        Spacer(minLength: 20)
                        
                        // 3. YouTube Button
                        Button(action: {
                            openVideo()
                        }) {
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
                                    gradient: Gradient(colors: [Color.red, Color(red: 0.8, green: 0, blue: 0)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
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
    
    private func openVideo() {
        // 1. Determine the base URL string
        var urlString: String
        // Prefer stored URL if valid
        if let stored = exercise?.videoUrl, !stored.isEmpty {
            urlString = stored
        } else {
            // Fallback to search
            let localizedName = exerciseName.localized()
            let suffix = LanguageManager.shared.currentLanguageCode == "en" ? "technique" : "техника выполнения"
            let searchQuery = "\(localizedName) \(suffix)"
            if let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                urlString = "https://www.youtube.com/results?search_query=\(encodedQuery)"
            } else {
                return
            }
        }

        // SECURITY: разрешаем только http(s) и youtube://. Без allowlist хранимый
        // в БД videoUrl мог содержать tel://, sms://, mailto:// или сторонние схемы,
        // а UIApplication.shared.open мог бы их сработать.
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

        // 2. Try to open in YouTube App (youtube:// scheme)
        let appUrlString = urlString
            .replacingOccurrences(of: "https://", with: "youtube://")
            .replacingOccurrences(of: "http://", with: "youtube://")

        if let appUrl = URL(string: appUrlString), UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
            return
        }

        // 3. Fallback to mobile browser
        var webUrlString = urlString
        if webUrlString.contains("www.youtube.com") {
             webUrlString = webUrlString.replacingOccurrences(of: "www.youtube.com", with: "m.youtube.com")
        }

        if let webUrl = URL(string: webUrlString) {
            UIApplication.shared.open(webUrl)
        }
    }
}

#Preview {
    ExerciseTechniqueDetailView(
        exerciseName: "Приседания со штангой"
    )
}
