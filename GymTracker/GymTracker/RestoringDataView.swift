//
//  RestoringDataView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct RestoringDataView: View {
    @Binding var isRestoring: Bool
    var onFinish: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var progressText = "analyzing_data"
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Animated Icon
                ZStack {
                    Circle()
                        .stroke(DesignSystem.Colors.neonGreen.opacity(0.3), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(DesignSystem.Colors.neonGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                    
                    Image(systemName: "icloud.and.arrow.down.fill")
                        .font(.title)
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                }
                
                VStack(spacing: 12) {
                    Text("Восстанавливаем данные...")
                        .font(DesignSystem.Typography.title3())
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                    
                    Text("Мы нашли вашу историю тренировок в облаке.\nПожалуйста, подождите.")
                        .font(DesignSystem.Typography.body())
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .task {
            // Capture the container for the detached task
            let container = modelContext.container
            
            // Delay slightly to let UI render first and animation start
            try? await Task.sleep(for: .seconds(0.3))
            
            // Use withTaskCancellationHandler to ensure cleanup happens
            await withTaskGroup(of: Void.self) { group in
                // Launch restore with timeout
                group.addTask {
                    // Timeout after 30 seconds
                    try? await Task.sleep(for: .seconds(30))
                    
                    #if DEBUG
                    print("⏱️ Restore timeout - proceeding anyway")
                    #endif
                    
                    await MainActor.run {
                        withAnimation {
                            isRestoring = false
                            onFinish()
                        }
                    }
                }
                
                // Actual restore operation
                group.addTask {
                    // Perform the restore
                    _ = await SyncManager.shared.restoreWorkoutsFromFirestore(container: container)
                    
                    // Restore Profile (Measurements)
                    await SyncManager.shared.restoreUserProfileFromFirestore(container: container)
                    
                    // Restore Programs
                    await SyncManager.shared.restoreProgramsFromFirestore(container: container)
                    
                    // Remove any duplicates that might have been created
                    await SyncManager.shared.removeDuplicateWorkouts(container: container)
                    
                    // Mark that we've restored data
                    UserDefaults.standard.set(true, forKey: "hasRestoredCloudData")
                    
                    // Small delay to show completion
                    try? await Task.sleep(for: .seconds(0.5))
                    
                    #if DEBUG
                    print("✅ Restore completed successfully")
                    #endif
                    
                    // Transition back to main content
                    await MainActor.run {
                        withAnimation {
                            isRestoring = false
                            onFinish()
                        }
                    }
                }
                
                // Wait for first to complete (either timeout or successful restore)
                await group.next()
                
                // Cancel remaining tasks
                group.cancelAll()
            }
        }
    }
}

#Preview {
    RestoringDataView(isRestoring: .constant(true)) {}
}
