//
//  WorkoutTrackerApp.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

@main
struct WorkoutTrackerApp: App {
    
    // Use shared instance to ensure consistent state across the app
    @StateObject private var authManager = AuthManager.shared
    @State private var isCheckingAuth = true
    
    init() {
        FirebaseApp.configure()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            WorkoutSession.self,
            WorkoutSet.self,
            BodyMeasurement.self,
            WeightRecord.self,
            Program.self,
            WorkoutDay.self,
            ExerciseTemplate.self
        ])
        
        do {
            let container = try ModelContainer(for: schema)
            print("✅ ModelContainer initialized")
            return container
        } catch {
            print("⚠️ Error: \(error)")
            
            // Reset database on error
            let config = ModelConfiguration(schema: schema)
            try? FileManager.default.removeItem(at: config.url)
            print("🗑️ DB reset")
            
            do {
                let container = try ModelContainer(for: schema)
                print("✅ Fresh DB created")
                return container
            } catch {
                fatalError("❌ Failed: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isCheckingAuth {
                    // Loading / Splash Screen
                    VStack(spacing: 20) {
                        Image("launch_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                        
                        ProgressView()
                            .tint(DesignSystem.Colors.neonGreen)
                            .scaleEffect(1.5)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DesignSystem.Colors.background)
                    .transition(.opacity)
                } else {
                    Group {
                        if authManager.isLoggedIn {
                            ContentViewWrapper()
                                .environmentObject(authManager)
                                .transition(.opacity)
                        } else {
                            LoginView()
                                .environmentObject(authManager) // LoginView uses implicit shared but passing environment is good practice
                                .transition(.opacity)
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .modelContainer(sharedModelContainer)
            .onAppear {
                checkAuthStatus()
            }
        }
    }
    
    private func checkAuthStatus() {
        // Quick verification:
        // Use UserDefaults to know if we EXPECT to be logged in
        let hasPreviousSession = UserDefaults.standard.bool(forKey: "isLoggedIn")
        
        if !hasPreviousSession {
            // No previous session, go straight to Login
            withAnimation {
                isCheckingAuth = false
            }
        } else {
            // We expect a session, wait a moment for Firebase/AuthManager to sync
            // AuthManager listener fires async.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    isCheckingAuth = false
                }
            }
        }
    }
}

// MARK: - Content View Wrapper

struct ContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasSeeded = false
    
    var body: some View {
        ContentView()
            .task {
                // Background seeding - non-blocking
                if !hasSeeded {
                    Task.detached(priority: .background) {
                        await MainActor.run {
                            ProgramSeeder.seedProgramsIfNeeded(context: modelContext)
                            ExerciseLibrary.migrateExerciseTypes(context: modelContext)
                            print("✅ Background seeding complete from ContentViewWrapper")
                        }
                    }
                    hasSeeded = true
                }
            }
    }
}
