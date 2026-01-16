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
            WeightRecord.self,
            BodyMeasurement.self,
            Program.self,
            WorkoutDay.self,
            ExerciseTemplate.self,
            WorkoutSession.self,
            WorkoutSet.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Failed to create ModelContainer: \(error)")
            
            // Attempt to delete the existing store and recreate (Nuclear option for dev)
            let fileManager = FileManager.default
            let storeURL = modelConfiguration.url
            
            print("Attempting to reset database at: \(storeURL.path)")
            
            do {
                if fileManager.fileExists(atPath: storeURL.path) {
                    try fileManager.removeItem(at: storeURL)
                    
                    // Also delete auxiliary files (wal, shm)
                    let shmURL = storeURL.appendingPathExtension("shm")
                    if fileManager.fileExists(atPath: shmURL.path) {
                         try fileManager.removeItem(at: shmURL)
                    }
                    
                    let walURL = storeURL.appendingPathExtension("wal")
                    if fileManager.fileExists(atPath: walURL.path) {
                         try fileManager.removeItem(at: walURL)
                    }
                }
                
                print("Database deleted. Retrying ModelContainer creation...")
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isCheckingAuth {
                    // Loading / Splash Screen
                    VStack(spacing: 20) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                        
                        Text("BODY FORGE")
                            .font(DesignSystem.Typography.title())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .tracking(2)
                        
                        ProgressView()
                            .tint(DesignSystem.Colors.neonGreen)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
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
            .onAppear {
                if !hasSeeded {
                    ProgramSeeder.seedProgramsIfNeeded(context: modelContext)
                    hasSeeded = true
                }
            }
    }
}
