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
    @StateObject private var languageManager = LanguageManager.shared
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
            ExerciseTemplate.self,
            CustomExercise.self  // Added for custom exercises sync
        ])
        
        do {
            let container = try ModelContainer(for: schema)
            #if DEBUG
            print("✅ ModelContainer initialized")
            #endif
            return container
        } catch {
            #if DEBUG
            print("⚠️ Error: \(error)")
            #endif
            
            // Reset database on error
            let config = ModelConfiguration(schema: schema)
            try? FileManager.default.removeItem(at: config.url)
            #if DEBUG
            print("🗑️ DB reset")
            #endif
            
            do {
                let container = try ModelContainer(for: schema)
                #if DEBUG
                print("✅ Fresh DB created")
                #endif
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
                            // Removed environmentObject from here if it was redundant, 
                            // but LoginView uses Singleton AuthManager.shared internally so it's fine.
                            // Keeping it clean.
                                .transition(.opacity)
                        }
                    }
                    .id(languageManager.appLanguage) // Force recreate views when language changes
                }
            }
            .preferredColorScheme(.dark)
            .modelContainer(sharedModelContainer)
            .environment(\.locale, languageManager.currentLocale)
            .environmentObject(languageManager)
            .onAppear {
                // Set ModelContainer for AuthManager (must be done here, not in init)
                authManager.setModelContainer(sharedModelContainer)
                checkAuthStatus()
            }
            .onChange(of: authManager.isLoggedIn) { _, isLoggedIn in
                if isLoggedIn {
                    checkForFreshInstall()
                }
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
    
    /// Check if DB is empty on login to trigger auto-restore
    private func checkForFreshInstall() {
        // Auto-restore disabled - user will manually sync via Settings
        // This prevents the RestoringDataView from appearing
        
        #if DEBUG
        print("ℹ️ Auto-restore disabled. User will sync manually from Settings.")
        #endif
    }
}

// MARK: - Content View Wrapper

struct ContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasSeeded = false
    
    var body: some View {
        ContentView()
            .task {
                // Capture needed values
                let container = modelContext.container
                
                // Fire-and-forget: Launch only seeding in background
                // This allows the view to appear immediately without blocking
                Task.detached(priority: .userInitiated) {

                    // Seeding (Local) - run in background context
                    let needsSeeding = await MainActor.run { !hasSeeded }
                    if needsSeeding {
                        // Create a background context for seeding
                        let bgContext = ModelContext(container)
                        
                        // Check if we actually need to seed (quick read)
                        let descriptor = FetchDescriptor<Program>()
                        let count = try? bgContext.fetchCount(descriptor)
                        
                        if count == 0 || count == nil {
                            // DB is empty, seed defaults
                            ProgramSeeder.seedProgramsIfNeeded(context: bgContext)
                        } else {
                            // Run migration/cleanup
                            ProgramSeeder.seedProgramsIfNeeded(context: bgContext)
                        }
                        
                        // Run exercise migration with safe error handling
                        await ExerciseLibrary.migrateExerciseTypes(container: container)
                        
                        await MainActor.run {
                            hasSeeded = true
                        }
                    }
                    
                    // All cloud restores removed - user will manually sync via Settings
                }
            }
    }
    
    // restoreWorkoutsFromFirestore moved to SyncManager
    
    // convertToWorkoutSession moved to SyncManager
}
