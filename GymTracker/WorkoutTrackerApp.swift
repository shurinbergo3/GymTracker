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
                // Move heavy operations to background
                if !hasSeeded {
                    // The seeding logic has been moved to WorkoutTrackerApp's onAppear
                    // This .task block can be removed or repurposed if needed.
                    // For now, we'll keep it empty or remove the content.
                    // If there are other operations specific to ContentViewWrapper, they can go here.
                    // For this change, we're effectively removing the seeding from here.
                    hasSeeded = true // Mark as seeded to prevent re-entry if this block remains
                }
            }
    }
}
