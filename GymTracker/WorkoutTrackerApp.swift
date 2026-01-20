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
    @State private var hasRestored = false
    
    var body: some View {
        ContentView()
            .task {
                // 1. FIRST: Restore workouts from Firestore (before seeding)
                if !hasRestored {
                    await restoreWorkoutsFromFirestore()
                    hasRestored = true
                }
                
                // 2. Background seeding - non-blocking
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
    
    /// Restore workout history from Firestore to SwiftData
    private func restoreWorkoutsFromFirestore() async {
        do {
            let firestoreWorkouts = try await FirestoreManager.shared.fetchHistory()
            
            guard !firestoreWorkouts.isEmpty else {
                print("📭 No workouts found in Firestore")
                return
            }
            
            // Check if workouts already exist in SwiftData to avoid duplicates
            let descriptor = FetchDescriptor<WorkoutSession>()
            let localSessions = (try? modelContext.fetch(descriptor)) ?? []
            
            print("📥 Found \(firestoreWorkouts.count) workouts in Firestore, \(localSessions.count) local")
            
            var restoredCount = 0
            
            // Convert Firestore workouts to SwiftData sessions
            for workout in firestoreWorkouts {
                // Skip if already exists (check by date + workout type)
                let exists = localSessions.contains { session in
                    Calendar.current.isDate(session.date, inSameDayAs: workout.date) &&
                    session.workoutDayName == workout.workoutType
                }
                
                if !exists {
                    let session = convertToWorkoutSession(workout)
                    modelContext.insert(session)
                    restoredCount += 1
                }
            }
            
            if restoredCount > 0 {
                try modelContext.save()
                print("✅ Restored \(restoredCount) workouts from Firestore")
            } else {
                print("ℹ️ All workouts already synced")
            }
        } catch {
            print("❌ Error restoring workouts: \(error)")
        }
    }
    
    /// Convert Firestore Workout to SwiftData WorkoutSession
    private func convertToWorkoutSession(_ workout: Workout) -> WorkoutSession {
        let session = WorkoutSession(
            workoutDayName: workout.workoutType,
            programName: "Restored"
        )
        session.date = workout.date
        session.endTime = workout.date.addingTimeInterval(workout.duration)
        session.calories = workout.calories
        session.notes = workout.notes
        session.isCompleted = true
        
        // Convert exercises to sets
        for exercise in workout.exercises {
            for set in exercise.sets {
                let workoutSet = WorkoutSet(
                    exerciseName: exercise.name,
                    weight: set.weight,
                    reps: set.reps,
                    setNumber: set.setNumber,
                    isWeighted: set.weight > 0
                )
                workoutSet.isCompleted = set.isCompleted
                workoutSet.session = session
                session.sets.append(workoutSet)
            }
        }
        
        return session
    }
}
