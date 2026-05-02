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
    @Environment(\.scenePhase) private var scenePhase
    @State private var isCheckingAuth = true
    @State private var isRestoringData = false
    @State private var dbError: Error? = nil
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
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
            AICoachMessage.self,
            AICoachWeeklySummary.self
        ])
        
        do {
            let container = try ModelContainer(for: schema)
            #if DEBUG
            print("✅ ModelContainer initialized")
            #endif
            return container
        } catch {
            #if DEBUG
            print("⚠️ Error: \(error). Attempting DB reset...")
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
                // Return a minimal in-memory container so app doesn't crash
                let memConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                return (try? ModelContainer(for: schema, configurations: memConfig))
                    ?? { fatalError("Cannot create even in-memory ModelContainer: \(error)") }()
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isCheckingAuth {
                    LaunchScreenView()
                        .transition(.opacity)
                } else {
                    Group {
                        if authManager.isLoggedIn {
                            if isRestoringData {
                                RestoringDataView(isRestoring: $isRestoringData, onFinish: {
                                    // Transition to content
                                    isRestoringData = false
                                })
                                .transition(.opacity)
                            } else {
                                ContentViewWrapper()
                                    .environmentObject(authManager)
                                    .transition(.opacity)
                            }
                        } else {
                            if !hasSeenOnboarding {
                                OnboardingView(hasSeenOnboarding: Binding(
                                    get: { hasSeenOnboarding },
                                    set: { hasSeenOnboarding = $0 }
                                ))
                                .transition(.opacity)
                            } else {
                                LoginView()
                                    .transition(.opacity)
                            }
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .id(languageManager.refreshID)
            .modelContainer(sharedModelContainer)
            .onAppear {
                checkAuthStatus()
                InactivityNotificationService.requestAuthorizationIfNeeded()
            }
            .onChange(of: authManager.isLoggedIn) { _, isLoggedIn in
                if isLoggedIn {
                    checkForFreshInstall()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    InactivityNotificationService.rescheduleOnAppOpen()
                    rescheduleDecayWarningsFromLatestSession()
                }
            }
        }
    }
    
    /// Reads the most-recent completed session and re-schedules decay warnings.
    /// Called on app foreground so notifications stay aligned with real workout history.
    private func rescheduleDecayWarningsFromLatestSession() {
        let context = sharedModelContainer.mainContext
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let latest = try? context.fetch(descriptor).first else {
            InactivityNotificationService.rescheduleDecayWarnings(lastWorkoutDate: nil, peakLevel: 1)
            return
        }

        let countDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true }
        )
        let total = (try? context.fetchCount(countDescriptor)) ?? 0
        let peak = GamificationCalculator.peakLevel(totalWorkouts: total)

        InactivityNotificationService.rescheduleDecayWarnings(
            lastWorkoutDate: latest.date,
            peakLevel: peak
        )
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
        // Only trigger if we are NOT already checking auth (i.e. this is a user-initiated login)
        // OR if it's auto-login but database is wiped.
        
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<WorkoutSession>()
        
        do {
            let count = try context.fetchCount(descriptor)
            if count == 0 {
                // Database is empty! Assume fresh install or wipe.
                // Trigger Restore Flow
                #if DEBUG
                print("🆕 Fresh install detected. Triggering auto-restore.")
                #endif
                withAnimation {
                    isRestoringData = true
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to check DB count: \(error)")
            #endif
        }
    }
}

// MARK: - Content View Wrapper

struct ContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasSeeded = false
    @State private var hasRestored = false
    
    var body: some View {
        ContentView()
            .task {
                let container = modelContext.container
                let needsSeed = !hasSeeded
                let needsRestore = !hasRestored
                
                Task.detached(priority: .userInitiated) {
                    if needsSeed {
                        let bgContext = ModelContext(container)
                        ProgramSeeder.seedProgramsIfNeeded(context: bgContext)
                        await ExerciseLibrary.migrateExerciseTypes(container: container)
                        await MainActor.run {
                            hasSeeded = true
                        }
                    }
                    
                    if needsRestore {
                        await restoreUserProfileFromFirestore()
                        await MainActor.run {
                            hasRestored = true
                        }
                    }
                }
            }
    }
    
    // restoreWorkoutsFromFirestore moved to SyncManager
    
    // convertToWorkoutSession moved to SyncManager
    
    /// Restore User Profile & Active Program from Firestore
    private func restoreUserProfileFromFirestore() async {
        guard let profileData = await SyncManager.shared.fetchUserProfile() else { return }
        
        // 1. Update or Create UserProfile
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        let profile: UserProfile
        
        if let existing = profiles.last {
            profile = existing
            // Only update if cloud is newer? Or just overwrite?
            // For now, trust cloud if fetching
            profile.height = profileData.height
            profile.age = profileData.age
            // Weight logic is complex (history), maybe skip or add new record
        } else {
            profile = UserProfile(height: profileData.height, initialWeight: profileData.weight, age: profileData.age)
            modelContext.insert(profile)
        }
        
        // 2. Activate Program
        if let activeName = profileData.activeProgramName {
            // Find program by name
            let progDescriptor = FetchDescriptor<Program>() // Fetch all to be safe
            if let allPrograms = try? modelContext.fetch(progDescriptor) {
                
                var found = false
                for program in allPrograms {
                    if program.name == activeName {
                        program.isActive = true
                        found = true
                        #if DEBUG
                        print("✅ Restored Active Program: \(activeName)")
                        #endif
                    } else {
                        // Deactivate others to ensure single source of truth
                        program.isActive = false
                    }
                }
                
                if !found {
                    #if DEBUG
                    print("⚠️ Active program '\(activeName)' not found locally")
                    #endif
                }
            }
        }
        
        try? modelContext.save()
        
        // Notify app to refresh (WorkoutManager listens to this)
        await MainActor.run {
            NotificationCenter.default.post(name: Notification.Name("ActiveProgramChanged"), object: nil)
        }
    }
}
